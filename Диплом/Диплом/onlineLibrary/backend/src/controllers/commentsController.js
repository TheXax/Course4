import Comment from '../models/Comment.js';
import User from '../models/User.js';

export async function addComment(req, res) {
  try {
    const userId = req.user.user_id;
    const { bookId } = req.params;
    const { comment_text } = req.body;
    if (!comment_text?.trim()) {
      return res.status(400).json({ message: 'Текст комментария обязателен' });
    }

    const comment = await Comment.create({
      user_id: userId,
      book_id: bookId,
      comment_text: comment_text.trim(),
      parent_id: null,
      is_admin_reply: false
    });
    res.json(comment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function replyToComment(req, res) {
  try {
    const userId = req.user.user_id;
    const { commentId } = req.params;
    const { comment_text } = req.body;

    if (!comment_text?.trim()) {
      return res.status(400).json({ message: 'Текст ответа обязателен' });
    }

    const parentComment = await Comment.findByPk(commentId);
    if (!parentComment) {
      return res.status(404).json({ message: 'Родительский комментарий не найден' });
    }

    if (parentComment.parent_id) {
      return res.status(400).json({ message: 'Нельзя отвечать на ответ администратора' });
    }

    const existingReply = await Comment.findOne({
      where: { parent_id: commentId, is_admin_reply: true }
    });

    if (existingReply) {
      return res.status(400).json({ message: 'Комментарий уже имеет ответ администратора' });
    }

    const reply = await Comment.create({
      user_id: userId,
      book_id: parentComment.book_id,
      comment_text: comment_text.trim(),
      parent_id: commentId,
      is_admin_reply: true
    });

    res.json(reply);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function listComments(req, res) {
  const { bookId } = req.params;
  const comments = await Comment.findAll({
    where: { book_id: bookId, parent_id: null },
    include: [
      { model: User, attributes: ['user_id', 'login'] },
      {
        model: Comment,
        as: 'Replies',
        include: [{ model: User, attributes: ['user_id', 'login'] }]
      }
    ],
    order: [
      ['created_at', 'DESC'],
      [{ model: Comment, as: 'Replies' }, 'created_at', 'ASC']
    ]
  });
  console.log('Comments with replies:', JSON.stringify(comments, null, 2));
  res.json(comments);
}

export async function deleteComment(req, res) {
  try {
    const { commentId } = req.params;
    const comment = await Comment.findByPk(commentId);
    if (!comment) return res.status(404).json({ message: 'Не найдено' });

    const isAdmin = req.user?.role_name === 'admin' || req.user?.role_id === 1;
    const isOwner = comment.user_id === req.user?.user_id;
    if (!isAdmin && !isOwner) return res.status(403).json({ message: 'Запрещено' });

    await comment.destroy();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}


