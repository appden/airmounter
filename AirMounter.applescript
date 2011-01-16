property app_name : "AirMounter"
property domain_name : "com.appden." & app_name
property daemon_path : "~/Library/LaunchAgents/" & domain_name & ".plist"
property my_path : ""

property growl_notifications : {"AirDisks Mounted"}
property growl_icon : "Finder"

property my_ssid : "SSID"
property router_ip : "10.0.1.1"
property mount_disks : {"volume1", "volume2"}

on run args
	set the text item delimiters of AppleScript to {" "}
	
	if class of args is not list then
		try
			if length of my_path is 0 then
				set the_buttons to {"Quit", "Setup"}
			else
				set the_buttons to {"Quit", "Disable", "Edit Configuration"}
			end if
			
			display dialog "Please select from the following:" buttons the_buttons with title app_name
			
			set button_pressed to button returned of the result
			if button_pressed is "Quit" then
				return
			else if button_pressed is "Disable" then
				try
					do shell script "rm " & daemon_path
				end try
				set my_path to ""
				return
			end if
			
			display dialog "Airport Network SSID" buttons {"Next"} default button "Next" default answer my_ssid with title app_name
			set my_ssid to the text returned of the result
			
			display dialog "Server Hostname or IP Address" buttons {"Next"} default button "Next" default answer router_ip with title app_name
			set router_ip to the text returned of the result
			
			display dialog "Volume Names (space separated)" buttons {"Done"} default button "Done" default answer mount_disks as text with title app_name
			set mount_disks to every word of the text returned of the result
			
			set the_path to POSIX path of (path to me)
			if my_path is not the_path then
				set my_path to the_path
				setDaemon for my_path
			end if
			
		on error m number n
			return
		end try
	end if
	
	set the_ssid to do shell script "/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk '/ SSID: / {print $2}'"
	if the_ssid is my_ssid then
		
		tell application "System Events" to set my_disks to the name of every disk where local volume is false
		
		set mounted_disks to ""
		repeat with the_volume in mount_disks
			try
				if my_disks does not contain the_volume then
					mount volume "afp://" & router_ip & "/" & the_volume
					set mounted_disks to mounted_disks & the_volume & return
				end if
			end try
		end repeat
		
		if (count of mounted_disks) is greater than 0 then growl(item 1 of growl_notifications, mounted_disks)
	end if
end run

on setDaemon for the_path
	tell application "System Events"
		set the parent_dictionary to make new property list item with properties {kind:record}
		set this_plistfile to make new property list file with properties {contents:parent_dictionary, name:daemon_path}
		
		make new property list item at end of property list items of contents of this_plistfile Â
			with properties {kind:string, name:"Label", value:domain_name}
		make new property list item at end of property list items of contents of this_plistfile Â
			with properties {kind:list, name:"ProgramArguments", value:{"osascript", the_path}}
		make new property list item at end of property list items of contents of this_plistfile Â
			with properties {kind:number, name:"StartInterval", value:60}
	end tell
end setDaemon

on growl(the_title, the_message)
	tell application "System Events" to set growl_running to exists application process "GrowlHelperApp"
	if growl_running then
		tell application "GrowlHelperApp"
			register as application app_name all notifications growl_notifications default notifications growl_notifications icon of application growl_icon
			notify with name the_title title the_title description the_message application name app_name
		end tell
	end if
end growl