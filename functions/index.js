const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNewEventCreationNotification = functions.https.onRequest(async (req, res) => {
    try {
        const { members, event } = req.body;
        console.log(req.body);

        if (!members || !event) {
            return res.status(400).json({ error: "Members and event data are required." });
        }

        const notifications = members
            .filter(member => member.device_token) // Skip members without tokens
            .map(async (member) => {
                try {
                    const message = {
                        token: member.device_token,
                        notification: {
                            title: "New Event Created",
                            body: `New event "${event.title}" created. Don't miss it!`,
                        },
                        data: {
                            eventId: event.id.toString(),
                            memberId: member.member_id.toString(),
                            title: event.title,
                            description: event.description,
                            location: event.location,
                            startTime: new Date(event.start_time).toISOString(),
                            endTime: new Date(event.end_time).toISOString(),
                            district: event.district,
                            district_id: event.ditrict_id.toString(),
                            state_id: member.state_id.toString(),
                        },
                    };

                    await admin.messaging().send(message);
                } catch (error) {
                    // Skip known invalid token errors without affecting the response
                    if (
                        error.code === "messaging/registration-token-not-registered" ||
                        error.code === "messaging/invalid-registration-token" ||
                        error.code === "messaging/invalid-argument"
                    ) {
                        console.warn(`Skipping invalid token for member ${member.member_id}`);
                    } else {
                        console.error(`Error sending message to ${member.member_id}:`, error);
                    }
                }
            });

        await Promise.all(notifications);

        return res.status(200).json({ message: "Notifications sent successfully to valid tokens!" });
    } catch (error) {
        console.error("Error sending notifications:", error);
        return res.status(500).json({
            error: "Failed to send notifications.",
            details: error.message || error,
            stack: error.stack,
        });
    }
});
