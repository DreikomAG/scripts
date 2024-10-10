        $fp = fopen('.\slapd.csv', 'r');
        if ($fp) {
            $record = '';
            while (!feof($fp)) {
                $line = trim(fgets($fp, 1024));
                $record .= "$line`n";
            }
            fclose($fp);
        }

        echo $record;
