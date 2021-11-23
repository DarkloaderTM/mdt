/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;




CREATE TABLE IF NOT EXISTS `vehicle_mdt` (
  `dbid` int(11) NOT NULL AUTO_INCREMENT,
  `license_plate` varchar(50) NOT NULL DEFAULT '',
  `stolen` longtext NOT NULL,
  `notes` varchar(255) DEFAULT '{}',
  `image` longtext NOT NULL,
  `code5` longtext NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `info` longtext NOT NULL,
  PRIMARY KEY (`dbid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `___mdw_bulletin` (
  `id` bigint(20) NOT NULL DEFAULT 0,
  `title` longtext NOT NULL,
  `info` longtext NOT NULL,
  `time` varchar(50) NOT NULL DEFAULT '0',
  `src` mediumtext NOT NULL,
  `author` mediumtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `___mdw_incidents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL,
  `author` varchar(100) NOT NULL,
  `time` varchar(100) NOT NULL,
  `details` longtext NOT NULL,
  `tags` longtext NOT NULL,
  `officers` longtext NOT NULL,
  `civilians` longtext NOT NULL,
  `evidence` longtext NOT NULL,
  `associated` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `___mdw_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` longtext NOT NULL,
  `time` mediumtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4;

/*!40000 ALTER TABLE `___mdw_logs` DISABLE KEYS */;
INSERT INTO `___mdw_logs` (`id`, `text`, `time`) VALUES
	(25, 'Carson Miller Revoked licenses type: Drive Edited Citizen Id: 24', '1635572269852'),
	(26, 'Carson Miller Revoked licenses type: Drive Edited Citizen Id: 24', '1635572271934'),
	(27, 'Carson Miller Revoked licenses type: Pilot Edited Citizen Id: 24', '1635572282645'),
	(28, 'Carson Miller Given licenses type: Pilot Edited Citizen Id: 24', '1635572286808');
/*!40000 ALTER TABLE `___mdw_logs` ENABLE KEYS */;


CREATE TABLE IF NOT EXISTS `___mdw_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(255) NOT NULL DEFAULT 'police',
  `name` varchar(255) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  `time` varchar(255) DEFAULT NULL,
  `profilepic` mediumtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4;

/*!40000 ALTER TABLE `___mdw_messages` DISABLE KEYS */;
INSERT INTO `___mdw_messages` (`id`, `job`, `name`, `message`, `time`, `profilepic`) VALUES
	(10, 'police', 'Carson Miller', 'Hey', '1634857901842', 'https://i.imgur.com/VlCWQdn.png'),
	(11, 'police', 'Carson Miller', 'Hi', '1634860966373', 'https://i.imgur.com/VlCWQdn.png'),
	(12, 'police', 'Carson Miller', 'Poggers', '1634860970375', 'https://i.imgur.com/VlCWQdn.png');
/*!40000 ALTER TABLE `___mdw_messages` ENABLE KEYS */;


CREATE TABLE IF NOT EXISTS `___mdw_profiles` (
  `idP` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(60) NOT NULL,
  `image` longtext DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `tags` longtext NOT NULL DEFAULT '{}',
  `gallery` longtext NOT NULL DEFAULT '{}',
  PRIMARY KEY (`idP`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `____mdw_bolos` (
  `dbid` int(11) NOT NULL AUTO_INCREMENT,
  `title` mediumtext DEFAULT NULL,
  `author` mediumtext DEFAULT NULL,
  `time` mediumtext DEFAULT NULL,
  `license_plate` mediumtext DEFAULT NULL,
  `owner` mediumtext DEFAULT NULL,
  `individual` varchar(60) NOT NULL DEFAULT '',
  `detail` longtext DEFAULT NULL,
  `tags` longtext DEFAULT NULL,
  `gallery` longtext DEFAULT NULL CHECK (json_valid(`gallery`)),
  `officers` longtext DEFAULT NULL,
  PRIMARY KEY (`dbid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `____mdw_reports` (
  `dbid` int(11) NOT NULL AUTO_INCREMENT,
  `title` mediumtext DEFAULT NULL,
  `type` mediumtext DEFAULT NULL,
  `author` mediumtext DEFAULT NULL,
  `time` mediumtext DEFAULT NULL,
  `detail` longtext DEFAULT NULL,
  `tags` longtext DEFAULT '[]',
  `gallery` longtext DEFAULT '[]',
  `officers` longtext DEFAULT '[]',
  `civsinvolved` longtext DEFAULT '[]',
  PRIMARY KEY (`dbid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
