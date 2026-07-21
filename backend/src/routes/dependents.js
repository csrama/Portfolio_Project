const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

const router = new Hono();

// Public endpoint - must be before auth middleware
router.get('/invite/:token', async (c) => {
  try {
    const token = c.req.param('token');
    const dependent = await pool.getDependentByInviteToken(token);
    if (!dependent) {
      return c.json({ error: 'رابط الدعوة غير صالح' }, 404);
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

    // Get caregiver info
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

    const { full_name, relationship, date_of_birth, invite } = body;
    const sendInvite = invite !== false; // default to true (send invite)

    if (!full_name || full_name.trim() === '') {
      return c.json({ error: 'الاسم الكامل مطلوب' }, 400);
    }
    if (!relationship) {
      return c.json({ error: 'العلاقة مطلوبة' }, 400);
    }

    // Create a placeholder user for the dependent
    const placeholderEmail = `dep_${Date.now()}_${Math.random().toString(36).substring(2, 8)}@direct.local`;
    const temporaryPassword = crypto.randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const newDependentUser = await pool.createUser({
      email: placeholderEmail.toLowerCase(),
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'dependent',
      is_active: true,
      is_onboarding_complete: false
    });

    console.log('Created placeholder user:', newDependentUser.id);

    let dependent;
    let inviteLink = null;
    let invitationToken = null;

    if (sendInvite) {
      // Generate invite token
      invitationToken = crypto.randomBytes(32).toString('hex');

      dependent = await pool.createDependent({
        caregiver_user_id: user.id,
        dependent_user_id: newDependentUser.id,
        full_name: full_name.trim(),
        date_of_birth: date_of_birth || null,
        relationship: relationship,
        invitation_status: 'pending',
        invitation_token: invitationToken
      });

      // Build the invite link
      const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
      inviteLink = `${baseUrl}/invite?token=${invitationToken}`;
    } else {
      // Add dependent directly - no invite needed
      dependent = await pool.createDependentDirect({
        caregiver_user_id: user.id,
        dependent_user_id: newDependentUser.id,
        full_name: full_name.trim(),
        date_of_birth: date_of_birth || null,
        relationship: relationship
      });
    }

    console.log('Created dependent relation:', dependent.id);

    return c.json({
      success: true,
      message: sendInvite ? 'تم إنشاء رابط الدعوة بنجاح' : 'تم إضافة التابع بنجاح',
      data: {
        invite_link: inviteLink,
        token: invitationToken,
        dependent: {
          id: dependent.id,
          full_name: full_name.trim(),
          relationship: relationship,
          status: dependent.invitation_status
        },
        caregiver: {
          full_name: user.full_name
        }
      }
    }, 201);

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

// Accept/claim an invite - links the logged-in user's account to this dependent
router.post('/invite/:token/accept', async (c) => {
  try {
    const token = c.req.param('token');
    const user = c.get('user');

    if (!user) {
      return c.json({ error: 'الرجاء تسجيل الدخول أولاً' }, 401);
    }

    const dependent = await pool.getDependentByInviteToken(token);
    if (!dependent) {
      return c.json({ error: 'رابط الدعوة غير صالح' }, 404);
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

    // Claim the invite - link this user to the dependent record
    const claimed = await pool.claimDependentInvite(token, user.id);
    if (!claimed) {
      return c.json({ error: 'فشل قبول الدعوة' }, 500);
    }

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