import db from '../models/index.js';

const User = db.User;




const checkAdmin = async (callerId) => {
  const caller = await User.findByPk(callerId, { attributes: ['id', 'role_id'] });
  if (!caller) {
    throw new Error('Người dùng không tồn tại');
  }
  if (caller.role_id !== 2) {
    throw new Error('Bạn không có quyền thực hiện hành động này');
  }
};

const getAllUser = async (callerId) => {
  try {
    await checkAdmin(callerId);

    const userList = await User.findAll({
      order: [['id', 'ASC']],
      attributes: ['id', 'username', 'email', 'role_id', 'status'],
    });
 
    return userList;

  } catch (err) {
    console.error('❌ Error fetching users:', err);
    throw err;
  }
};

const updateUserRole = async (callerId, userId, newRoleId) => { 
  try {
    await checkAdmin(callerId);

    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('Người dùng không tồn tại');
    }

    // ❌ Không cho admin chỉnh role của admin khác
    if (user.role_id === 2) {
      throw new Error('Bạn không thể chỉnh sửa vai trò của admin khác');
    }

    user.role_id = newRoleId;
    await user.save();

    return { message: 'Cập nhật vai trò thành công', user };
  } catch (err) {
    console.error('❌ Error updating user role:', err);
    throw err;
  }
};

const deleteUser = async (callerId, userId) => {
  try {
    await checkAdmin(callerId);

    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('Người dùng không tồn tại');
    }

    // ❌ Không cho admin xoá admin khác
    if (user.role_id === 2) {
      throw new Error('Bạn không thể xoá admin khác');
    }

    await user.destroy();
    return { message: 'Xoá người dùng thành công' };
  } catch (err) {
    console.error('❌ Error deleting user:', err);
    throw err;
  }
};
const lockUser = async (callerId, userId, newStatus) => {
  try {
    await checkAdmin(callerId);

    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('Người dùng không tồn tại');
    }

    // ❌ Không cho admin khoá admin khác
    if (user.role_id === 2) {
      throw new Error('Bạn không thể khoá admin khác');
    }

    user.status = newStatus;
    await user.save();

    return { message: 'Cập nhật trạng thái tài khoản thành công', user };
  } catch (err) {
    console.error('❌ Error updating user status:', err);
    throw err;
  }
};

const updateUser = async (callerId, userId, updateData) => {
  try {
    await checkAdmin(callerId);

    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('Người dùng không tồn tại');
    }

    // ❌ Không cho admin chỉnh sửa admin khác (ngoại trừ chính mình nếu cần, nhưng thường dùng route riêng)
    if (user.role_id === 2 && callerId !== user.id) {
      throw new Error('Bạn không thể chỉnh sửa admin khác');
    }

    // Cập nhật các trường được phép
    if (updateData.username) user.username = updateData.username;
    if (updateData.email) user.email = updateData.email;
    if (updateData.role_id !== undefined) {
        // Chỉ admin mới đổi được role, và không tự hạ role mình nếu là admin cuối cùng (tạm bỏ qua check admin cuối)
        user.role_id = updateData.role_id;
    }
    if (updateData.status !== undefined) user.status = updateData.status;

    await user.save();

    return { message: 'Cập nhật thông tin người dùng thành công', user };
  } catch (err) {
    console.error('❌ Error updating user:', err);
    throw err;
  }
};

export {
  getAllUser,
  updateUserRole,
  deleteUser,
  lockUser,
  updateUser
};
