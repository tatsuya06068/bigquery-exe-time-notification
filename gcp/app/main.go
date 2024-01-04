package myCloudEventFunction

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/slack-go/slack"

	// "time"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	functions.CloudEvent("HelloAuditLog", helloAuditLog)
}

// AuditLogEntry represents a LogEntry as described at
// https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry
type AuditLogEntry struct {
	ProtoPayload *AuditLogProtoPayload `json:"protoPayload"`
}

// AuditLogProtoPayload represents AuditLog within the LogEntry.protoPayload
// See https://cloud.google.com/logging/docs/reference/audit/auditlog/rest/Shared.Types/AuditLog
type AuditLogProtoPayload struct {
	MethodName         string                    `json:"methodName"`
	ResourceName       string                    `json:"resourceName"`
	AuthenticationInfo map[string]interface{}    `json:"authenticationInfo"`
	ServiceData        AuditLogJobCompletedEvent `json:"serviceData"`
}

type AuditLogJobCompletedEvent struct {
	JobCompletedEvent AuditLogJob `json:"jobCompletedEvent"`
}

type AuditLogJob struct {
	Job AuditLogJobStatistics `json:"job"`
}

type AuditLogJobStatistics struct {
	JobStatistics AuditLogjobStatistics `json:"jobStatistics"`
}

type AuditLogjobStatistics struct {
	StartTime string `json:"startTime"`
	EndTime   string `json:"endTime"`
}

// helloAuditLog receives a CloudEvent containing an AuditLogEntry, and logs a few fields.
func helloAuditLog(ctx context.Context, e event.Event) error {

	// アクセストークンを使用してクライアントを生成する
	tkn := os.Getenv("SLACK_TOKEN")
	c := slack.New(tkn)

	// Print out details from the CloudEvent itself
	// See https://github.com/cloudevents/spec/blob/v1.0.1/spec.md#subject
	// for details on the Subject field
	c.PostMessage("C06CAF2QQBW", slack.MsgOptionText(fmt.Sprintf("Event Type: %s", e.Type()), true))
	c.PostMessage("C06CAF2QQBW", slack.MsgOptionText(fmt.Sprintf("Subject: %s", e.Subject()), true))

	// Decode the Cloud Audit Logging message embedded in the CloudEvent
	logentry := &AuditLogEntry{}
	if err := e.DataAs(logentry); err != nil {
		ferr := fmt.Errorf("event.DataAs: %w", err)
		log.Print(ferr)
		return ferr
	}
	// Print out some of the information contained in the Cloud Audit Logging event
	// See https://cloud.google.com/logging/docs/audit#audit_log_entry_structure
	// for a full description of available fields.
	log.Printf("API Method: %s", logentry.ProtoPayload.MethodName)
	log.Printf("Resource Name: %s", logentry.ProtoPayload.ResourceName)

	c.PostMessage("C06CAF2QQBW", slack.MsgOptionText(fmt.Sprintf("StartTime: %s", logentry.ProtoPayload.ServiceData.JobCompletedEvent.Job.JobStatistics.StartTime), true))
	c.PostMessage("C06CAF2QQBW", slack.MsgOptionText(fmt.Sprintf("EndTime: %s", logentry.ProtoPayload.ServiceData.JobCompletedEvent.Job.JobStatistics.EndTime), true))
	c.PostMessage("C06CAF2QQBW", slack.MsgOptionText(fmt.Sprintf("Resource Name: %s", logentry.ProtoPayload.ResourceName), true))

	return nil
}
