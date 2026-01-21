
const {CognitoIdentityProviderClient, SignUpCommand} = require('@aws-sdk/client-cognito-identity-provider');
const UserModel = require('../models/userModel');
const client = new CognitoIdentityProviderClient({region: 'eu-north-1'});

const CLIENT_ID = '4p46vv30o2nkal2g06d2dvde5n';

//define a lambda function to send sign-up requests

exports.signUp = async (event) => {
    const {email, fullName, password} = JSON.parse(event.body);

    //parameter required by Cognito's SignUpCommand

    const params = {
        ClientId: CLIENT_ID,
        Username: email,
        Password: password,
        UserAttributes: [
            {Name: 'email', Value: email},
            {Name: 'name', Value: fullName},
        ]

    };

    try {
        //create the SignUpCommand object with the prepared parameters

        const command = new SignUpCommand(params);

        await client.send(command);

        const newUser = new UserModel(email, fullName);
        await newUser.save();

        return {
            statusCode: 200,
            body: JSON.stringify({mesg: 'User successfully signed up'}),
        };

    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({error: 'unexpected error', details: error.message})
        };

    }
    



};