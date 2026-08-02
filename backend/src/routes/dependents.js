const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

const router = new Hono();

router.get('/invite/:token', async (c) => {
  try {
    const token = c.req.param('token');
    const dependent = await pool.getDependentByInviteToken(token);
    if (!dependent) return c.json({ error: 'رابط الدعوة غير صالح' }, 404);
    if (dependent.invitation_status !== 'pending') return c.json({ error: 'تم معالجة هذه الدعوة مسبقاً' }, 400);

    const daysDiff = (new Date() - new Date(dependent.invited_at)) / (1000 * 60 * 60 * 24);
    if (daysDiff > 7) return c.json({ error: 'انتهت صلاحية الدعوة' }, 410);

    const caregiver = await pool.findUserById(dependent.caregiver_user_id);
    return c.json({
      success: true,
      data: {
        dependent_name: dependent.full_name,
        relationship: dependent.relationship,
        caregiver_name: caregiver ? caregiver.full_name : 'مقدم الرعاية',
        invited_at: dependent.invited_at
      }
    });
  } catch (error) {
    console.error('Error fetching invite info:', error);
    return c.json({ error: 'فشل جلب معلومات الدعوة' }, 500);
  }
});

router.use('*', authMiddleware);

router.get('/', async (c) => {
  try {
    const user = c.get('user');
    const dependents = await pool.listDependentsWithUsers(user.id);
    return c.json({ success: true, data: dependents || [] });
  } catch (error) {
    console.error('Error fetching dependents:', error);
    return c.json({ error: 'فشل جلب التابعين' }, 500);
  }
});

router.get('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');
    if (isNaN(id)) return c.json({ error: 'معرف التابع غير صحيح' }, 400);

    const dependent = await pool.getDependentWithUser(id, user.id);
    if (!dependent) return c.json({ error: 'التابع غير موجود' }, 404);

    return c.json({ success: true, data: dependent });
  } catch (error) {
    console.error('Error fetching dependent:', error);
    return c.json({ error: 'فشل جلب التابع' }, 500);
  }
});

router.post('/create-with-account', async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const { full_name, email, password, relationship, date_of_birth } = body;

    if (!full_name || !email || !password || !relationship) {
      return c.json({ error: 'جميع الحقول مطلوبة' }, 400);
    }
    if (password.length < 6) {
      return c.json({ error: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' }, 400);
    }
    if (email.toLowerCase() === user.email) {
      return c.json({ error: 'لا يمكنك إضافة نفسك كتابع' }, 400);
    }

    const existing = await pool.findUserByEmail(email.toLowerCase());
    if (existing) {
      return c.json({ error: 'هذا البريد الإلكتروني مستخدم مسبقاً' }, 409);
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const newDepUser = await pool.createUser({
      email: email.toLowerCase(),
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'dependent',
      is_active: true,
      is_onboarding_complete: false,
    });

    let dob = null;
    if (date_of_birth) {
      const parsed = new Date(date_of_birth);
      if (!isNaN(parsed.getTime())) {
        dob = parsed.toISOString();
      }
    }

    const result = await pool.query(
      `INSERT INTO dependents
        (caregiver_user_id, dependent_user_id, full_name, relationship, date_of_birth, invitation_status, accepted_at)
       VALUES ($1, $2, $3, $4, $5, 'accepted', NOW())
       RETURNING *`,
      [user.id, newDepUser.id, full_name.trim(), relationship, dob]
    );

    return c.json({
      success: true,
      message: 'تم إنشاء حساب التابع وربطه بنجاح. شارك بيانات الدخول معه.',
      data: {
        dependent: result.rows[0],
        login_email: email.toLowerCase()
      }
    }, 201);

  } catch (error) {
    console.error('Error creating dependent with account:', error);
    return c.json({ error: 'فشل إنشاء حساب التابع' }, 500);
  }
});

router.post('/link-request', caregiverCheck, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const { email, relationship } = body;

    if (!email || !relationship) {
      return c.json({ error: 'البريد الإلكتروني والعلاقة مطلوبان' }, 400);
    }
    if (email.toLowerCase() === user.email) {
      return c.json({ error: 'لا يمكنك ربط نفسك كتابع' }, 400);
    }

    const target = await pool.findUserByEmail(email.toLowerCase());
    if (!target) {
      return c.json({
        error: 'لا يوجد حساب بهذا البريد الإلكتروني',
        hint: 'يمكنك إنشاء حساب جديد للتابع بدلاً من ذلك'
      }, 404);
    }

    const existingLink = await pool.query(
      `SELECT * FROM dependents WHERE caregiver_user_id = $1 AND dependent_user_id = $2`,
      [user.id, target.id]
    );
    if (existingLink.rows.length > 0) {
      const status = existingLink.rows[0].invitation_status;
      if (status === 'accepted') return c.json({ error: 'هذا التابع مرتبط بحسابك بالفعل' }, 409);
      if (status === 'pending') return c.json({ error: 'يوجد طلب ربط سابق بانتظار رد التابع' }, 409);
    }

    const result = await pool.query(
      `INSERT INTO dependents
        (caregiver_user_id, dependent_user_id, full_name, relationship, invitation_status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [user.id, target.id, target.full_name || email, relationship]
    );

    return c.json({
      success: true,
      message: 'تم إرسال طلب الربط، بانتظار موافقة التابع',
      data: { request_id: result.rows[0].id, status: 'pending' }
    }, 201);

  } catch (error) {
    console.error('Error creating link request:', error);
    return c.json({ error: 'فشل إرسال طلب الربط' }, 500);
  }
});

router.get('/link-requests/incoming', async (c) => {
  try {
    const user = c.get('user');
    const result = await pool.query(
      `SELECT d.*, u.full_name as caregiver_name, u.email as caregiver_email
       FROM dependents d
       JOIN users u ON u.id = d.caregiver_user_id
       WHERE d.dependent_user_id = $1 AND d.invitation_status = 'pending'
       ORDER BY d.created_at DESC`,
      [user.id]
    );
    return c.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching link requests:', error);
    return c.json({ error: 'فشل جلب طلبات الربط' }, 500);
  }
});

router.put('/link-request/:id/respond', async (c) => {
  try {
    const user = c.get('user');
    const dependentId = parseInt(c.req.param('id'));
    const { action } = await c.req.json().catch(() => ({}));

    if (isNaN(dependentId)) return c.json({ error: 'معرف الطلب غير صحيح' }, 400);
    if (!['accept', 'reject'].includes(action)) {
      return c.json({ error: 'الإجراء يجب أن يكون accept أو reject' }, 400);
    }

    const request = await pool.query(
      `SELECT * FROM dependents WHERE id = $1 AND dependent_user_id = $2 AND invitation_status = 'pending'`,
      [dependentId, user.id]
    );
    if (request.rows.length === 0) {
      return c.json({ error: 'الطلب غير موجود أو تمت معالجته مسبقاً' }, 404);
    }

    const newStatus = action === 'accept' ? 'accepted' : 'rejected';
    await pool.query(
      `UPDATE dependents
       SET invitation_status = $1,
           accepted_at = ${action === 'accept' ? 'NOW()' : 'NULL'},
           updated_at = NOW()
       WHERE id = $2`,
      [newStatus, dependentId]
    );

    return c.json({
      success: true,
      message: action === 'accept' ? 'تم قبول طلب الربط بنجاح' : 'تم رفض طلب الربط',
    });
  } catch (error) {
    console.error('Error responding to link request:', error);
    return c.json({ error: 'فشل معالجة الطلب' }, 500);
  }
});

router.put('/:id', caregiverCheck, async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');
    const body = await c.req.json();

    if (isNaN(id)) return c.json({ error: 'معرف التابع غير صحيح' }, 400);

    const existing = await pool.getDependentWithUser(id, user.id);
    if (!existing) return c.json({ error: 'التابع غير موجود' }, 404);

    const updated = await pool.updateDependent(id, user.id, {
      relationship: body.relationship
    });

    if (body.full_name) {
      await pool.updateUser(existing.dependent_user_id, { full_name: body.full_name });
    }

    return c.json({ success: true, message: 'تم تحديث التابع بنجاح', data: updated });
  } catch (error) {
    console.error('Error updating dependent:', error);
    return c.json({ error: 'فشل تحديث التابع' }, 500);
  }
});

router.delete('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');

    if (isNaN(id)) return c.json({ error: 'معرف التابع غير صحيح' }, 400);

    const dependent = await pool.getDependentWithUser(id, user.id);
    if (!dependent) return c.json({ error: 'التابع غير موجود' }, 404);

    const deleted = await pool.deleteDependentCascade(id, user.id);
    if (!deleted) {
      return c.json({ error: 'فشل حذف التابع' }, 500);
    }

    if (dependent.dependent_user_id) {
      await pool.deleteUser(dependent.dependent_user_id);
    }

    return c.json({ success: true, message: 'تم حذف التابع وجميع البيانات المرتبطة به بنجاح' });
  } catch (error) {
    console.error('Error deleting dependent:', error);
    return c.json({ error: 'فشل حذف التابع: ' + error.message }, 500);
  }
});

router.post('/invite/:token/accept', async (c) => {
  try {
    const token = c.req.param('token');
    const user = c.get('user');

    if (!user) return c.json({ error: 'الرجاء تسجيل الدخول أولاً' }, 401);

    const dependent = await pool.getDependentByInviteToken(token);
    if (!dependent) return c.json({ error: 'رابط الدعوة غير صالح' }, 404);
    if (dependent.invitation_status !== 'pending') return c.json({ error: 'تم معالجة هذه الدعوة مسبقاً' }, 400);

    const daysDiff = (new Date() - new Date(dependent.invited_at)) / (1000 * 60 * 60 * 24);
    if (daysDiff > 7) return c.json({ error: 'انتهت صلاحية الدعوة' }, 410);

    const claimed = await pool.claimDependentInvite(token, user.id);
    if (!claimed) return c.json({ error: 'فشل قبول الدعوة' }, 500);

    return c.json({ success: true, message: 'تم قبول الدعوة بنجاح' });
  } catch (error) {
    console.error('Error accepting invite:', error);
    return c.json({ error: 'فشل قبول الدعوة' }, 500);
  }
});

router.get('/:id/medications', async (c) => {
  try {
    const dependentId = parseInt(c.req.param('id'));
    const user = c.get('user');

    if (isNaN(dependentId)) return c.json({ error: 'معرف التابع غير صحيح' }, 400);

    const dependent = await pool.getDependentWithUser(dependentId, user.id);
    if (!dependent) return c.json({ error: 'التابع غير موجود' }, 404);

    
    const result = await pool.query(
      `SELECT * FROM medications 
       WHERE dependent_id = $1 
          OR (user_id = $2 AND dependent_id IS NULL)
       ORDER BY created_at DESC`,
      [dependentId, dependent.dependent_user_id]
    );

    return c.json({ success: true, data: result.rows || [] });
  } catch (error) {
    console.error('Error fetching dependent medications:', error);
    return c.json({ error: 'فشل جلب أدوية التابع' }, 500);
  }
});

module.exports = router;
