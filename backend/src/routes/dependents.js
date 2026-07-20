const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

const router = new Hono();

router.use('*', authMiddleware);

router.get('/', async (c) => {
  try {
    const user = c.get('user');
    const dependents = await pool.listDependentsWithUsers(user.id);
    return c.json({
      success: true,
      data: dependents || []
    });
  } catch (error) {
    console.error('Error fetching dependents:', error);
    return c.json({ error: 'فشل جلب التابعين' }, 500);
  }
});

router.get('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');

    if (isNaN(id)) {
      return c.json({ error: 'معرف التابع غير صحيح' }, 400);
    }

    const dependent = await pool.getDependentWithUser(id, user.id);
    if (!dependent) {
      return c.json({ error: 'التابع غير موجود' }, 404);
    }

    return c.json({
      success: true,
      data: dependent
    });
  } catch (error) {
    console.error('Error fetching dependent:', error);
    return c.json({ error: 'فشل جلب التابع' }, 500);
  }
});

router.post('/', caregiverCheck, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json();

    console.log('Received body:', body);

    const { email, full_name, relationship, date_of_birth } = body;

    if (!full_name || full_name.trim() === '') {
      return c.json({ error: 'الاسم الكامل مطلوب' }, 400);
    }
    if (!relationship) {
      return c.json({ error: 'العلاقة مطلوبة' }, 400);
    }

    let finalEmail = email;
    let isTemporaryEmail = false;
    
    if (!email || email.trim() === '') {
      finalEmail = `dependent_${Date.now()}_${Math.random().toString(36).substring(2, 8)}@temp.local`;
      isTemporaryEmail = true;
      console.log('Generated temporary email:', finalEmail);
    }

    if (!isTemporaryEmail) {
      const existingUser = await pool.findUserByEmail(finalEmail);
      if (existingUser) {
        return c.json({ error: 'البريد الإلكتروني مستخدم بالفعل' }, 409);
      }
    }

    const temporaryPassword = crypto.randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const newDependent = await pool.createUser({
      email: finalEmail.toLowerCase(),
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'dependent',
      is_active: true,
      is_onboarding_complete: false
    });

    console.log('Created user:', newDependent.id, newDependent.email);

    const dependent = await pool.createDependent({
      caregiver_user_id: user.id,
      dependent_user_id: newDependent.id,
      full_name: full_name.trim(),
      date_of_birth: date_of_birth || null,
      relationship: relationship,
      invitation_status: isTemporaryEmail ? 'accepted' : 'pending',
      invitation_token: isTemporaryEmail ? null : crypto.randomBytes(32).toString('hex')
    });

    console.log('Created dependent relation:', dependent.id);

    const responseData = {
      success: true,
      message: isTemporaryEmail 
        ? 'تم إضافة التابع بنجاح' 
        : 'تم إرسال الدعوة بنجاح',
      data: {
        dependent: {
          id: dependent.id,
          relationship: dependent.relationship,
          status: dependent.invitation_status
        },
        user: {
          id: newDependent.id,
          email: newDependent.email,
          full_name: newDependent.full_name
        }
      }
    };

    if (isTemporaryEmail) {
      responseData.data.temporaryPassword = temporaryPassword;
    }

    return c.json(responseData, 201);

  } catch (error) {
    console.error('Error creating dependent:', error);
    return c.json({ error: 'فشل إضافة التابع' }, 500);
  }
});

router.put('/:id', caregiverCheck, async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');
    const body = await c.req.json();

    if (isNaN(id)) {
      return c.json({ error: 'معرف التابع غير صحيح' }, 400);
    }

    const existing = await pool.getDependentWithUser(id, user.id);
    if (!existing) {
      return c.json({ error: 'التابع غير موجود' }, 404);
    }

    const updated = await pool.updateDependent(id, user.id, {
      relationship: body.relationship
    });

    if (body.full_name) {
      await pool.updateUser(existing.dependent_user_id, {
        full_name: body.full_name
      });
    }

    return c.json({
      success: true,
      message: 'تم تحديث التابع بنجاح',
      data: updated
    });
  } catch (error) {
    console.error('Error updating dependent:', error);
    return c.json({ error: 'فشل تحديث التابع' }, 500);
  }
});

router.delete('/:id', caregiverCheck, async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');

    if (isNaN(id)) {
      return c.json({ error: 'معرف التابع غير صحيح' }, 400);
    }

    const dependent = await pool.getDependentWithUser(id, user.id);
    if (!dependent) {
      return c.json({ error: 'التابع غير موجود' }, 404);
    }

    const dependentUserId = dependent.dependent_user_id;

    await pool.deleteDependent(id, user.id);
    await pool.deleteUser(dependentUserId);

    return c.json({
      success: true,
      message: 'تم حذف التابع بنجاح'
    });
  } catch (error) {
    console.error('Error deleting dependent:', error);
    return c.json({ error: 'فشل حذف التابع' }, 500);
  }
});

router.post('/invite/:token/accept', async (c) => {
  try {
    const token = c.req.param('token');
    const user = c.get('user');

    const dependent = await pool.getDependentByInviteToken(token);
    if (!dependent) {
      return c.json({ error: 'رابط الدعوة غير صالح' }, 404);
    }

    if (dependent.dependent_user_id !== user.id) {
      return c.json({ error: 'هذه الدعوة ليست لك' }, 403);
    }

    if (dependent.invitation_status !== 'pending') {
      return c.json({ error: 'تم معالجة هذه الدعوة مسبقاً' }, 400);
    }

    const invitedAt = new Date(dependent.invited_at);
    const now = new Date();
    const daysDiff = (now - invitedAt) / (1000 * 60 * 60 * 24);
    if (daysDiff > 7) {
      return c.json({ error: 'انتهت صلاحية الدعوة' }, 410);
    }

    await pool.acceptDependentInvite(dependent.id);

    return c.json({
      success: true,
      message: 'تم قبول الدعوة بنجاح'
    });
  } catch (error) {
    console.error('Error accepting invite:', error);
    return c.json({ error: 'فشل قبول الدعوة' }, 500);
  }
});

router.get('/:id/medications', async (c) => {
  try {
    const dependentId = parseInt(c.req.param('id'));
    const user = c.get('user');

    if (isNaN(dependentId)) {
      return c.json({ error: 'معرف التابع غير صحيح' }, 400);
    }

    const dependent = await pool.getDependentWithUser(dependentId, user.id);
    if (!dependent) {
      return c.json({ error: 'التابع غير موجود' }, 404);
    }

    const medications = await pool.listMedications(dependent.dependent_user_id);

    return c.json({
      success: true,
      data: medications || []
    });
  } catch (error) {
    console.error('Error fetching dependent medications:', error);
    return c.json({ error: 'فشل جلب أدوية التابع' }, 500);
  }
});

module.exports = router;