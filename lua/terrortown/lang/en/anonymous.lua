local L = LANG.GetLanguageTableReference("en")

--GENERAL ROLE LANGUAGE STRINGS
L[ANONYMOUS.name] = "Anonymous"
L["info_popup_" .. ANONYMOUS.name] = [[You are Anonymous. Kill everyone else.

You probably have friends and probably don't know who they are.]]
L["body_found_" .. ANONYMOUS.abbr] = "They were Anonymous."
L["search_role_" .. ANONYMOUS.abbr] = "This person was Anonymous!"
L["target_" .. ANONYMOUS.name] = "Anonymous"
L["ttt2_desc_" .. ANONYMOUS.name] = [[You are Anonymous. Kill everyone else.

You probably have friends and probably don't know who they are.]]

--ANONYMOUS TEAM
L[TEAM_ANONYMOUS] = "Team Anonymous"
L["hilite_win_" .. TEAM_ANONYMOUS] = "TEAM ANONYMOUS WON"
L["win_" .. TEAM_ANONYMOUS] = "Anonymous has won!"
L["ev_win_" .. TEAM_ANONYMOUS] = "Anonymous won the round!"

-- OTHER ROLE LANGUAGE STRINGS
L["num_teammates_" .. ANONYMOUS.name] = "There are {n} players on the Anonymous team."

--EVENT STRINGS
-- Need to be very specifically worded, due to how the system translates them.
L["title_event_anon_force"] = "An Innocent player was forced to be Anonymous"
L["desc_event_anon_force"] = "Innocent player {name} was forced to be Anonymous."
L["title_event_anon_inform"] = "An Anonymous player made a friend :)"
L["desc_event_anon_inform"] = "Anonymous player {name1} knew that {name2} was also Anonymous."
