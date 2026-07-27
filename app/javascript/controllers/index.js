import { application } from "controllers/application"

import NotificationController from "controllers/notification_controller"
application.register("notification", NotificationController)
