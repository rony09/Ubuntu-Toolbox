WIP readme

Version 0.6bxx (the 0.6 beta series)
Major new features in this version:
- User remover has been fully implemented.
- Log directories are now changeable by script var
- Utility menu has been implemented
- Debug output has been added


Description:
This is a general security best practice implementation untility intended for use on all relatively recent versions of Ubuntu (>= 12.04). It suppoerts automation of common tasks like the removeal of unauthorized users and the automatic password changing of users. A few useful untility commands ahve been included in the utility menu. Current and planned features are:
- Interactive mode: Done
- Unsupervised mode: Maybe?
- Unauthorized user remover: Done
- Unauthorized admin remover: Remover implementation pending
- User passwording: Done
- Update enabler: A few things left to do
- Firewall enabler: Done
- Server Remover: Done
- PAM password history: To be implemented
- Misc utilities



IMPORTANT: EDIT THE SCRIPT BEFORE RUNNING! Especially the password block.

To RUN: type "sudo bash SecScrypt.sh" in terminal. USE BASH!

OPERATION NOTE:
When it asks "Are you...." during startup, say no if it says root. You want to type in the username of the currently logged in account. Failure to do this will result in your account being set to the new password and other problems in newer versions.
