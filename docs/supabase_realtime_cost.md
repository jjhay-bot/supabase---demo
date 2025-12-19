# Supabase Realtime Subscription Cost Considerations

## Key Points

- **Supabase Realtime pricing is based on the number of active (simultaneous) realtime connections and the number of messages/events sent.**
- **You are NOT billed for total registered users, only for users who are actively connected (listening) at the same time.**
- **If a user closes the app/tab or disconnects, they no longer count toward your active connection limit.**
- **Monthly Active Users (MAU) in Supabase pricing is based on unique users who authenticate via Supabase Auth in a given month, not the number of rows in your `users` table.**

## Supabase Pro Plan (as of 2025)

- $25/month
- 500 simultaneous realtime connections (subscriptions/listeners)
- 3,000,000 realtime messages/events per month
- 100,000 monthly active users (MAU) via Supabase Auth, then $0.00325 per MAU
- 8 GB disk size per project, then $0.125 per GB
- 250 GB egress, then $0.09 per GB
- 250 GB cached egress, then $0.03 per GB
- 100 GB file storage, then $0.021 per GB
- Email support, daily backups, 7-day log retention

## Example Scenarios

| Scenario                                 | Active Connections | Messages/Month | Plan Needed | Cost   |
|------------------------------------------|-------------------|---------------|-------------|--------|
| 1,000 registered users, 50 online        | 50                | Low           | Pro         | $25/mo |
| 1,000 registered users, 500 online       | 500               | Moderate      | Pro         | $25/mo |
| 1,000 registered users, 1,000 online     | 1,000             | Moderate      | Custom      | >$25/mo|
| 10,000 registered users, 200 online      | 200               | Moderate      | Pro         | $25/mo |

- If you exceed 500 simultaneous connections or 3,000,000 messages/month, you need a custom plan (contact Supabase).
- Message volume is rarely the bottleneck for most apps; simultaneous connections are usually the main limit.
- MAU is only counted for users who authenticate via Supabase Auth in a given month.

## Best Practices

- Only keep subscriptions open when needed (e.g., when user is on a page that needs live updates).
- Unsubscribe/close connections when not needed to reduce active connection count.
- Monitor your usage in the Supabase dashboard.
- Handle subscription errors gracefully in your frontend if you hit connection limits.

## Summary

- **Plan for your peak number of simultaneous users, not your total user base.**
- **Pro plan is sufficient for up to 500 active listeners at once.**
- **No extra cost unless you exceed plan limits.**
- **MAU is based on Supabase Auth usage, not your own user table.**

For the latest details, always check the [Supabase Pricing Page](https://supabase.com/pricing).
