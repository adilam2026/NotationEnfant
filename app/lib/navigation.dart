import 'package:flutter/widgets.dart';

/// App-wide navigator key. Lets [AuthProvider] pop back to the root route
/// when a session appears while an auth screen (login, "check your email")
/// is pushed on top — most importantly when the app resumes from the
/// Supabase email-confirmation deep link while one of those screens was
/// showing, with no local widget around to drive the navigation itself.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
