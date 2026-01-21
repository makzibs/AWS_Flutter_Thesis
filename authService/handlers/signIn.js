const {CognitoIdentityProviderClient, InitiateAuthCommand} = require('@aws-sdk/client-cognito-identity-provider');

const client = new CognitoIdentityProviderClient({region: 'eu-north-1'});

const CLIENT_ID = '4p46vv30o2nkal2g06d2dvde5n';

exports.signIn = async (event) => {
    const {email, password} = JSON.parse(event.body);

    //parameter required by Cognito's SignUpCommand

    const params = {
        ClientId: CLIENT_ID,
        AuthFlow: 'USER_PASSWORD_AUTH',
        AuthParameters: {
            USERNAME: email,
            PASSWORD: password
        }
    
    };

    try {
        //create the ConfirmSignUpCommand object with the prepared parameters

        const command = new InitiateAuthCommand(params);
        const response = await client.send(command);

       

        return {
            statusCode: 200,
            body: JSON.stringify({mesg: 'User successfully signed in', tokens: response.AuthenticationResult}),
        };

    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({error: 'sign-in failed', details: error.message})
        };

    }
    



};