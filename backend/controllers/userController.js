const { mongoose } = require('mongoose');
const User = require('../models/user');
const moment = require('moment');
const jwt = require('jsonwebtoken');
const SECRET_KEY = process.env.JWT_SECRET || 1234567890;

// login
exports.loginUser = async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await User.findOne({ email: email })
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        } else if (user.password !== password) {
            return res.status(401).json({ message: 'Contraseña incorrecta' });
        }

        const token = jwt.sign({ id: user.userId, email: email }, SECRET_KEY, { expiresIn: '90d' });

        res.status(201).json({ data: user, token: token });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Error del servidor' });
    }
}

// Obtener datos de usuario
exports.getUser = async (req, res) => {
    try {
        const user = await User.findOne({ 
          userId: req.user.id 
        });
        if (!user) return res.status(404).json({ message: 'Usuario no encontrado' });
        res.json(user);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error del servidor' });
    }
}

// register
exports.createUser = async (req, res) => {
    let { name, last_name, uid_rfid, birthday, home_address, phone_number, email, password  } = req.body;
    let user_id = new mongoose.Types.ObjectId();

    // Cambiar el formato de la fecha de nacimiento

    const parsedBirthday = moment(birthday, 'DD/MM/YYYY', true);
    if (!parsedBirthday.isValid()) {
        return res.status(400).json({ message: 'Fecha de nacimiento inválida' });
    }

    birthday = parsedBirthday.toDate();

    try {
        const user = new User({
            userId: user_id,
            uid_rfid: uid_rfid,
            name: name,
            last_name: last_name,
            birthday: birthday,
            home_address: home_address,
            phone_number: phone_number,
            email: email,
            password: password,
        });

        await user.save();

        const token = jwt.sign({ id: user.userId, email: email }, SECRET_KEY, { expiresIn: '90d' });
        
        res.status(201).json({ data: user, token: token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error del servidor' });
    }
}