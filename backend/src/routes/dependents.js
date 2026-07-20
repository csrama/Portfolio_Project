const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

const router = new Hono();

router.use('*', authMiddleware);


router.post('/', caregiverCheck, async (c) => {
  try {
    const user = c.get('user'); 
    const body = await c.req.json();

    const { email, full_name, relationship, date_of_birth } = body;

    if (!email || !email.includes('@')) {
      return c.json({ error: 'البريد الإلكتروني مطلوب' }, 400);
    }
    if (!full_name || full_name.trim() === '') {
      return c.json({ error: 'الاسم الكامل مطلوب' }, 400);
    }
    if (!relationship) {
      return c.json({ error: 'العلاقة مطلوبة' }, 400);
    }

    const existingUser = await pool.findUserByEmail(email);
    if (existingUser) {
      return c.json({ error: 'هذا البريد مستخدم بالفعل' }, 409);
    }

    const temporaryPassword = crypto.randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const newDependent = await pool.createUser({
      email: email.toLowerCase(),
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'dependent',
      is_active: true,
      is_onboarding_complete: false
    });

    const dependent = await pool.createDependent({
      caregiver_user_id: user.id,
      dependent_user_id: newDependent.id,
      relationship: relationship,
      invitation_status: 'pending',
      invitation_token: crypto.randomBytes(32).toString('hex')
    });


    return c.json({
      success: true,
      message: 'تم إنشاء حساب التابع وإرسال الدعوة',
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
        },
        temporaryPassword: temporaryPassword  
      }
    }, 201);

  } catch (error) {
    console.error('Error creating dependent:', error);
    return c.json({ error: 'فشل إضافة التابع' }, 500);
  }
});


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
      relationship: body.relationship,
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
      message: 'تم حذف التابع وحسابه بنجاح'
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
      return c.json({ error: 'هذا الرابط ليس لك' }, 403);
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
      return c.json({ error: 'التابع غير موجود أو لا يخصك' }, 404);
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