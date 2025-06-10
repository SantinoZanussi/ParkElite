const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    uid_rfid: {
        type: String,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    last_name: {
        type: String,
        required: true
    },
    phone_number: {
        type: Number,
        ref: 'Celular',
        required: true
    },
    birthday: {
        type: Date,
        ref: 'Cumpleaños',
        required: true
    },
    home_address: {
        type: String,
        ref: 'Dirección',
        required: true
    },
    email: {
        type: String,
        required: true
    },
    password: {
        type: String,
        required: true
    },
    code: {
        type: Number,
        required: true,
        unique: true,
        parse: true,
    }
});

module.exports = mongoose.model('User', userSchema);