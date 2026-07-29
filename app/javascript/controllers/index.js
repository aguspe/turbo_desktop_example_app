import { application } from "controllers/application"

import NotificationController from "controllers/notification_controller"
application.register("notification", NotificationController)

import ExportController from "controllers/export_controller"
application.register("export", ExportController)

import ImportController from "controllers/import_controller"
application.register("import", ImportController)

import ClipboardController from "controllers/clipboard_controller"
application.register("clipboard", ClipboardController)

import AutostartController from "controllers/autostart_controller"
application.register("autostart", AutostartController)
