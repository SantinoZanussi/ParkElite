const { mongoose } = require('mongoose');
const User = require('../models/user');

// login
exports.getUser = async (req, res) => {
    try {
        const users = await User.find({ 
          userId: req.user.id 
        }).populate('User');
        res.json(users);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error del servidor' });
    }
}

// register
exports.createUser = async (req, res) => {
    const { name, last_name, birthday, home_address, phone_number, email, password  } = req.body;
    let user_id = new mongoose.Types.ObjectId();
    try {
        const user = new User({
            userId: user_id,
            name: name,
            last_name: last_name,
            birthday: birthday,
            home_address: home_address,
            phone_number: phone_number,
            email: email,
            password: password,
        });

        await user.save();
        res.status(201).json(user);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error del servidor' });
    }
}