const { Hono } = require('hono');
const { pool } = require('../db/pool');
const { authMiddleware } = require('../middleware/auth');
const { caregiverCheck } = require('../middleware/caregiverCheck');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { z } = require('zod');

const router = new Hono();

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

const newDependentSchema = z.object({
  full_name: z.string().trim().min(1),
  email: z.string().trim().email().transform((v) => v.toLowerCase()),
  password: z.string().min(6),
  relationship: z.enum(['spouse', 'child', 'parent', 'sibling', 'other'])
});

router.post('/new', caregiverCheck, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const parsed = newDependentSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0]?.message || 'بيانات غير صحيحة' }, 400);
    }
    const { full_name, email, password, relationship } = parsed.data;

    if (email === user.email) {
      return c.json({ error: 'لا يمكنك إضافة نفسك كتابع' }, 400);
    }

    const existing = await pool.findUserByEmail(email);
    if (existing) {
      return c.json(
        { error: 'البريد الإلكتروني مستخدم بالفعل، استخدم خيار "ربط تابع لديه حساب"' },
        409
      );
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const dependentUser = await pool.createUser({
      email,
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'dependent',
      is_active: true,
      is_onboarding_complete: false
    });

    const dependent = await pool.createDependentDirect({
      caregiver_user_id: user.id,
      dependent_user_id: dependentUser.id,
      full_name: full_name.trim(),
      relationship
    });

    return c.json(
      {
        success: true,
        message: 'تم إنشاء حساب التابع وربطه بنجاح. شارك بيانات الدخول معه.',
        data: {
          dependent: { id: dependent.id, full_name: full_name.trim(), relationship, status: 'accepted' },
          login_email: email
        }
      },
      201
    );
  } catch (error) {
    console.error('Error creating new dependent:', error);
    return c.json({ error: 'فشل إضافة التابع' }, 500);
  }
});

const linkRequestSchema = z.object({
  email: z.string().trim().email().transform((v) => v.toLowerCase()),
  relationship: z.enum(['spouse', 'child', 'parent', 'sibling', 'other'])
});

router.post('/link-request', caregiverCheck, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const parsed = linkRequestSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: parsed.error.issues[0]?.message || 'بيانات غير صحيحة' }, 400);
    }
    const { email, relationship } = parsed.data;

    if (email === user.email) {
      return c.json({ error: 'لا يمكنك ربط نفسك كتابع' }, 400);
    }

    const target = await pool.findUserByEmail(email);
    if (!target) {
      return c.json(
        { error: 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني', hint: 'يمكنك إنشاء حساب جديد للتابع بدلاً من ذلك' },
        404
      );
    }

    if (target.user_type === 'caregiver') {
      return c.json({ error: 'هذا البريد مسجل كحساب مقدم رعاية ولا يمكن ربطه كتابع' }, 400);
    }

    const existingLink = await pool.findDependentLink(user.id, target.id);
    if (existingLink) {
      if (existingLink.invitation_status === 'accepted') {
        return c.json({ error: 'هذا التابع مرتبط بحسابك بالفعل' }, 409);
      }
      if (existingLink.invitation_status === 'pending') {
        return c.json({ error: 'يوجد طلب ربط سابق بانتظار رد التابع' }, 409);
      }
    }

    const request = await pool.createDependentLinkRequest({
      caregiver_user_id: user.id,
      dependent_user_id: target.id,
      full_name: target.full_name || email,
      relationship
    });

    return c.json(
      { success: true, message: 'تم إرسال طلب الربط، بانتظار موافقة التابع', data: { request_id: request.id, status: 'pending' } },
      201
    );
  } catch (error) {
    console.error('Error creating link request:', error);
    return c.json({ error: 'فشل إرسال طلب الربط' }, 500);
  }
});

router.get('/requests', async (c) => {
  try {
    const user = c.get('user');
    const requests = await pool.listIncomingRequests(user.id);
    return c.json({ success: true, data: requests });
  } catch (error) {
    console.error('Error fetching incoming requests:', error);
    return c.json({ error: 'فشل جلب طلبات الربط' }, 500);
  }
});

router.post('/requests/:id/accept', async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');
    if (isNaN(id)) return c.json({ error: 'معرف الطلب غير صحيح' }, 400);

    const result = await pool.respondToLinkRequest(id, user.id, true);
    if (!result) return c.json({ error: 'الطلب غير موجود أو تمت معالجته مسبقاً' }, 404);

    return c.json({ success: true, message: 'تم قبول طلب الربط', data: result });
  } catch (error) {
    console.error('Error accepting request:', error);
    return c.json({ error: 'فشل قبول الطلب' }, 500);
  }
});

router.post('/requests/:id/reject', async (c) => {
  try {
    const id = parseInt(c.req.param('id'));
    const user = c.get('user');
    if (isNaN(id)) return c.json({ error: 'معرف الطلب غير صحيح' }, 400);

    const result = await pool.respondToLinkRequest(id, user.id, false);
    if (!result) return c.json({ error: 'الطلب غير موجود أو تمت معالجته مسبقاً' }, 404);

    return c.json({ success: true, message: 'تم رفض طلب الربط', data: result });
  } catch (error) {
    console.error('Error rejecting request:', error);
    return c.json({ error: 'فشل رفض الطلب' }, 500);
  }
});

router.post('/', caregiverCheck, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json();

    console.log('Received body:', body);

    const { full_name, relationship, date_of_birth, invite } = body;
    const sendInvite = invite !== false;

    if (!full_name || full_name.trim() === '') {
      return c.json({ error: 'الاسم الكامل مطلوب' }, 400);
    }
    if (!relationship) {
      return c.json({ error: 'العلاقة مطلوبة' }, 400);
    }

    const placeholderEmail = `dep_${Date.now()}_${Math.random().toString(36).substring(2, 8)}@direct.local`;
    const temporaryPassword = crypto.randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const newDependentUser = await pool.createUser({
      email: placeholderEmail.toLowerCase(),
      password_hash: passwordHash,
      full_name: full_name.trim(),
      user_type: 'patient',
      is_active: true,
      is_onboarding_complete: false
    });

    console.log('Created placeholder user:', newDependentUser.id);

    let dependent;
    let inviteLink = null;
    let invitationToken = null;

    if (sendInvite) {
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

      const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
      inviteLink = `${baseUrl}/invite?token=${invitationToken}`;
    } else {
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
      return c
