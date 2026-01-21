const {CognitoIdentityProviderClient, ConfirmSignUpCommand} = require('@aws-sdk/client-cognito-identity-provider');

const client = new CognitoIdentityProviderClient({region: 'eu-north-1'});

const CLIENT_ID = '4p46vv30o2nkal2g06d2dvde5n';

exports.confirmSignUp = async (event) => {
    const {email, confirmationCode} = JSON.parse(event.body);

    //parameter required by Cognito's SignUpCommand

    const params = {
        ClientId: CLIENT_ID,
        Username: email,
        ConfirmationCode: confirmationCode,
    };

    try {
        //create the ConfirmSignUpCommand object with the prepared parameters

        const command = new ConfirmSignUpCommand(params);

        await client.send(command);

        return {
            statusCode: 200,
            body: JSON.stringify({mesg: 'User successfully confirmed'}),
        };

    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({error: 'failed to confirm sign-up', details: error.message})
        };

    }
    



};