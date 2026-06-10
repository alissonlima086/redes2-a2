<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '__DB_HOST__';
$CFG->dbname    = '__DB_NAME__';
$CFG->dbuser    = '__DB_USER__';
$CFG->dbpass    = '__DB_PASS__';
$CFG->prefix    = 'mdl_';

$CFG->wwwroot   = '__WWWROOT__';
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0770;
$CFG->reverseproxy         = true;

require_once(__DIR__ . '/lib/setup.php');
