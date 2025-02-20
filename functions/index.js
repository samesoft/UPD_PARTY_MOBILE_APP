const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNewEventCreationNotification = functions.https.onRequest(async (req, res) => {
    try {
        const { members, event } = req.body;

        if (!members || !event) {
            return res.status(400).json({ error: "Members and event data are required." });
        }

        const notifications = members.map((member) => {
            if (!member.device_token) return null; // Skip if no FCM token

            // Ensure all required fields are present and valid
            if (!event.id || !member.member_id || member.state_id || !event.title || !event.description || !event.location || !event.start_time || !event.end_time || !event.district || !event.ditrict_id) {
                console.error("Missing or invalid event/member data");
                return null; // Skip this member
            }

            const message = {
                token: member.device_token,
                notification: {
                    title: "New Event Created",
                    body: `New event "${event.title}" created. Don't miss it!`,
                },
                data: {
                    eventId: event.id.toString(), // Ensure this is a string
                    memberId: member.member_id.toString(), // Ensure this is a string
                    title: event.title, // Assuming this is already a string
                    description: event.description, // Assuming this is already a string
                    location: event.location, // Assuming this is already a string
                    startTime: new Date(event.start_time).toISOString(), // Convert to string
                    endTime: new Date(event.end_time).toISOString(), // Convert to string
                    district: event.district, // Assuming this is already a string
                    district_id: event.ditrict_id.toString(), // Ensure this is a string
                    state_id: member.state_id.toString() // Ensure this is a
                },
            };

            return admin.messaging().send(message);
        }).filter(Boolean); // Remove null values

        await Promise.all(notifications);

        return res.status(200).json({ message: "Notifications sent successfully!" });
    } catch (error) {
        console.error("Error sending notifications:", error);
        return res.status(500).json({ 
            error: "Failed to send notifications.", 
            details: error.message || error,
            stack: error.stack // Include the stack trace for debugging
        });
    }
});