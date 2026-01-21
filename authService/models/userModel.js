const {DynamoDBClient, PutItemCommand} = require('@aws-sdk/client-dynamodb');
const crypto = require('crypto');

const TABLE_NAME = 'Users';

const dynamoClient = new DynamoDBClient({region: 'eu-north-1'});


//user model class to represet a user and handle database operations

class UserModel {

    constructor(email, fullName) {
        this.userId = crypto.randomUUID();//Generatre a unique use ID
        this.email = email;
        this.fullName = fullName;
        this.state = ""; //Default empty string for state
        this.city = "";
        this.locality = "";
        this.createdAt = new Date().toISOString()
    }


    // save the user to the database

    async save() {
        const params = {
            TableName: TABLE_NAME,
            Item: {
                userId: {S: this.userId},
                email: {S: this.email},
                fullName: {S: this.fullName},
                state: {S: this.state},
                city: {S: this.city},
                locality: {S: this.locality},
                createdAt: {S: this.createdAt}
            },
        };
        try {
            await dynamoClient.send(new PutItemCommand(params));
        } catch (error) {
            throw error;
        }

    }
    
}

module.exports = UserModel;