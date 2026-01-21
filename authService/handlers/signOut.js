const {CognitoIdentityProviderClient, GlobalSignOutCommand} = require('@aws-sdk/client-cognito-identity-provider');

const client = new CognitoIdentityProviderClient({region: 'eu-north-1'});



exports.signOut = async (event) => {
    const {accessToken} = JSON.parse(event.body);

    //parameter required by Cognito's SignUpCommand

    const params = {
        AccessToken: accessToken, 
    };

    try {
        //create the ConfirmSignUpCommand object with the prepared parameters

        const command = new GlobalSignOutCommand(params);
        await client.send(command);

       

        return {
            statusCode: 200,
            body: JSON.stringify({mesg: 'User successfully signed out'}),
        };

    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({error: 'unexpected error', details: error.message})
        };

    }
    



};