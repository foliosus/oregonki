<?php

function isWinter () {
  date_default_timezone_set('America/Los_Angeles');
	$now = getdate();
	$month = $now['mon'];
	if ($month >= 11 || $month <=3) {
		$is_winter = true;
	} else {
		$is_winter = false;
	}
	return $is_winter;
};

function pathDepth($filename) {
	return substr_count($filename,'/',1);
};

class Event {
	var $start_date;
	var $duration;
	var $start_time;
	var $title;
	var $description;
	var $location;
	var $dojo;
	var $fullDate;
	var $fullStartDate;

	function Event ($ev) {
	  date_default_timezone_set('America/Los_Angeles');
		foreach ($ev as $k=>$v)
			$this->$k = $ev[$k];
		$this->start_date = strtotime($this->start_date);
		$this->fullStartDate = date("l F jS",$this->start_date);
		if ($this->duration > 1) {
			$this->fullDate = $this->fullStartDate . " &ndash; " . date("l F jS",$this->start_date + ($this->duration - 1)*24*60*60);
		} else {
			$this->fullDate = $this->fullStartDate;
		};
	}

	function fullTitle () {
		return $this->title;
	}

	function fullDescription () {
		return $this->description;
	}

	function year () {
		return date("Y",$this->start_date);
	}

	function month () {
		return date("F",$this->start_date);
	}

	function fullLocation($linked = false) {
		switch ($this->location) {
			case "Kiatsu":
				$location = "the Personal Kiatsu School in Tigard";
				$link = "/locations/kiatsu.php";
			break;
			case "SE":
				$location = "the SE Portland dojo";
				$link = "/locations/se_portland.php";
			break;
			case "";
				$location = "all dojos";
				$link = null;
			break;
			default:
				$location = "the " . $this->location . " dojo";
				$link = "/locations/" . strtolower($this->location) . ".php";
		};
		return ($linked && $link) ? "<a href=\"$link\" title=\"Get directions to $location\">$location</a>" : $location;
	}
};

function event_compare($ev1, $ev2) {
	if ($ev1->start_date == $ev2->start_date) {
		if ($ev1->title == $ev2->title) {
			return 0;
		};
		return ($ev1->title < $ev2->title) ? -1 : 1;
	};
	return ($ev1->start_date < $ev2->start_date) ? -1 : 1;
};

function after_today($ev) {
	if ($ev->start_date > strtotime("now")) {
		return true;
	} else {
		return false;
	};
};

function parse_event($values) {
   for ($i=0; $i < count($values); $i++) {
       $ev[$values[$i]["tag"]] = $values[$i]["value"];
   };
   return new Event($ev);
};

function load_events() {
	if(!empty($_ENV['RBENV_VERSION'])) {
		// In local dev mode
		$filename = 'source/events.xml';
	} else {
		// On the server
		$filename = 'events.xml';
	}
	$events = array();

	// Read XML
	$data = implode("", file($filename));
	$parser = xml_parser_create();
	xml_parser_set_option($parser, XML_OPTION_CASE_FOLDING, 0);
	xml_parser_set_option($parser, XML_OPTION_SKIP_WHITE, 1);
	xml_parse_into_struct($parser, $data, $values, $tags);
	xml_parser_free($parser);

	foreach ($tags as $key=>$val) {
	   if ($key == "event") {
		   $evranges = $val;
			for ($i=0; $i < count($evranges); $i+=2) {
				$offset = $evranges[$i] + 1;
				$len = $evranges[$i + 1] - $offset;
				$events[] = parse_event(array_slice($values, $offset, $len));
			};
	   } else {
		   continue;
	   };
	};

	// Remove dates prior to today
	$events = array_filter($events, "after_today");

	// Sort the events by date
	usort($events,"event_compare");

	return $events;
}; // function load_events

function upcoming_events($num_events) {
	// Initialize output
	$output = "";

	// Load XML data
	$events = load_events();

	$num_events = min($num_events, count($events));

	// walk through first $num_events events and output 'em
	for ($i=0; $i < $num_events; $i++) {
		$output .= "\n\t\t\t<li><a href=\"/events.php#event$i\" title=\"At " . $events[$i]->fullLocation() . "\">" . $events[$i]->fullTitle() . "</a>";
		$output .= "<span class=\"date\">" . $events[$i]->fullStartDate . "</span></li>";
	};

	return $output;
} // function random_photos ()

function full_calendar($events) {
	$output = '';
	$e = 0; // events counter
	$today = getdate();
	$start_month = $today["mon"] + 0;
	$end_month = $start_month + 3;
	$duration_counter = 0;

	for ($month = $start_month; $month < $end_month; $month++) {
		$this_month = mktime(8,0,0,$month,1);
		$first_of_the_month = getdate($this_month);

		$output .= "\n<table class=\"calendar\">";
		$output .= "\n\t<thead>";
		$output .= "\n\t\t<tr><th colspan=\"7\">" . $first_of_the_month["month"] . "</th></tr>";
		$output .= "\n\t\t<tr><td>Sun</td><td>Mon</td><td>Tue</td><td>Wed</td><td>Thu</td><td>Fri</td><td>Sat</td></tr>";
		$output .= "\n\t</thead>";
		$output .= "\n\t<tbody>";

		$output .= "\n\t\t<tr>";

		// pad out the beginning of the month with empty cells
		for ($i = 0; $i < $first_of_the_month["wday"]; $i++) {
			$output .= "\n\t\t\t<td>&nbsp;</td>";
		}

		// now render every day of the month
		$last_day = date("t",$this_month) + 0;
		for ($j = 1; $j <= $last_day; $j++) {
			$today_stamp = mktime(8,0,0,$month,$j);
			$today = getdate($today_stamp);
			if ($today["wday"] == 0) {
				$output .= "\n\t\t</tr>";
				$output .= "\n\t\t<tr>";
			};
			if (date("l F jS",$today_stamp) == $events[$e]->fullStartDate || $duration_counter > 0) {
				$output .= "\n\t\t\t<td class=\"has_event\"><a href=\"#event$e\" title=\"".  $events[$e]->fullTitle() ."\">$j</a></td>";
				if ($duration_counter > 0) {
					$duration_counter--;
				} elseif ($events[$e]->duration > 1) {
					$duration_counter = $events[$e]->duration - 1;
				};
				if ($duration_counter == 0 || $events[$e]->duration == 1) {
					$duration_counter = 0;
					do {
						$e++;
					} while ($events[$e - 1]->fullStartDate == $events[$e]->fullStartDate);
				};
			} else {
				$output .= "\n\t\t\t<td>$j</td>";
			};
		}	// every day of the month

		// pad out the end of the month with empty cells
		for ($i = $today["wday"] + 1; $i < 7; $i++) {
			$output .= "\n\t\t\t<td>&nbsp;</td>";
		}

		$output .= "\n\t\t</tr>";

		$output .= "\n\t</tbody>";
		$output .= "\n</table>";

	}; // for each month

	return $output;
}

function full_events ($events = array(), $filename = 'events.ics') {
  $output = '';

	if (count($events) == 0) {
		$events = load_events();
	}
	if (count($events) == 0) {
		return $output;
	}

  // .ics link
  $output .= "\n<p><a href=\"webcal://" . $GLOBALS['_SERVER']['HTTP_HOST'] . "/" . $filename . "\">Subscribe to this calendar</a></p>";

	// Prepare calendar view
	$calendar = full_calendar($events);
	if (sizeof(trim($calendar)) > 0) {
		$output .= "\n<div class=\"calendars\" id=\"calendar\">\n" . full_calendar($events) . "\n</div>";
	}

	// Prepare list view
	$prev_year = '';
	$prev_month = '';
	for ($i=0; $i < count($events); $i++) { // walk through events and output 'em
		if ($events[$i]->year() != $prev_year) {
			$prev_year = $events[$i]->year();
		};
		if ($events[$i]->month() != $prev_month) {
			if ($prev_month != '') {
				$output .= "\n</ul>";
			};
			$prev_month = $events[$i]->month();
			$output .= "\n<h2>$prev_month, $prev_year</h2>";
			$output .= "\n<ul>";
		};
		$output .= "\n<li>";
		$output .= "\n<h3 id=\"event$i\">" . $events[$i]->fullTitle() . "</h3>";
		$output .= "\n<p class=\"small date\">" . $events[$i]->fullDate;
		if (strlen($events[$i]->start_time) > 0) {
			$output .= ", " . $events[$i]->start_time . ",";
		};
		$output .= " at " . $events[$i]->fullLocation(true) . "</p>";
		$output .= "\n<p>" . $events[$i]->fullDescription() . "</p>";
		$output .= "\n</li>";
	};
	$output .= "\n</ul>";

	return $output;
} // function full_events

function dojo_events ($dojo) {
	$GLOBALS['dojo'] = $dojo;

	function event_for_dojo($ev) {
		global $dojo;

		if ($ev->dojo == "" || $ev->location == $dojo) {
			return true;
		} else {
			if (strpos($ev->dojo, $dojo) === false) {
				return false;
			} else {
				return true;
			};
		};
	};

	$events = load_events();

	$events = array_filter($events, "event_for_dojo");
	usort($events, "event_compare");

	if (count($events) > 0) {
		return full_events($events, str_replace('/location', 'location', str_replace('.php', '.ics', $GLOBALS['_SERVER']['SCRIPT_NAME'])));
	} else {
		return "<p>No upcoming events.</p>";
	};
}

?>