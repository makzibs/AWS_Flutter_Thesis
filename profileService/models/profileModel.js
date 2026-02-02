const { DynamoDBClient, PutItemCommand, GetItemCommand, UpdateItemCommand } = require('@aws-sdk/client-dynamodb');
const { marshall, unmarshall } = require('@aws-sdk/util-dynamodb');

const TABLE_NAME = 'UserProfiles';
const dynamoClient = new DynamoDBClient({ region: 'eu-north-1' });

class ProfileModel {
    constructor(userId, fullName, bio, hobbies) {
        this.userId = userId;
        this.fullName = fullName;
        this.bio = bio || '';
        this.hobbies = hobbies || [];
        this.createdAt = new Date().toISOString();
    }

    // Method to create a new profile entry
    async create() {
        const params = {
            TableName: TABLE_NAME,
            Item: marshall({
              userId: this.userId,
           fullName: this.fullName,
          bio: this.bio,
         hobbies: this.hobbies,
         createdAt: this.createdAt,
         }), // The marshall function converts the JS object to DynamoDB format
        };
        try {
            await dynamoClient.send(new PutItemCommand(params));
            return this;
        } catch (error) {
            console.error("Error creating profile:", error);
            throw error;
        }
    }

    // Static method to get a profile by userId
    static async get(userId) {
        const params = {
            TableName: TABLE_NAME,
            Key: marshall({ userId }),
        };
        try {
            const { Item } = await dynamoClient.send(new GetItemCommand(params));
            // The unmarshall function converts the DynamoDB format back to a JS object
            return Item ? unmarshall(Item) : null;
        } catch (error) {
            console.error("Error getting profile:", error);
            throw error;
        }
    }

    // Static method to update a profile
    static async update(userId, data) {
        // Dynamically build the UpdateExpression and ExpressionAttributeValues
        const updateKeys = Object.keys(data);
        const updateExpression = 'set ' + updateKeys.map(key => `#${key} = :${key}`).join(', ');
        const expressionAttributeNames = updateKeys.reduce((acc, key) => ({ ...acc, [`#${key}`]: key }), {});
        const expressionAttributeValues = marshall(updateKeys.reduce((acc, key) => ({ ...acc, [`:${key}`]: data[key] }), {}));

        const params = {
            TableName: TABLE_NAME,
            Key: marshall({ userId }),
            UpdateExpression: updateExpression,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW',
        };

        try {
            const { Attributes } = await dynamoClient.send(new UpdateItemCommand(params));
            return unmarshall(Attributes);
        } catch (error) {
            console.error("Error updating profile:", error);
            throw error;
        }
    }
}

module.exports = ProfileModel;