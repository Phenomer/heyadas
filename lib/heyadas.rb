# coding: utf-8

require 'sqlite3'

class Heyadas
  def initialize
    @db = SQLite3::Database.new('heyadas.db')
    @db.execute('PRAGMA foreign_keys = true;')
    @db.results_as_hash =  true
    init_db
  end

  # 初回起動時にデータベースのテーブルを作成
  def init_db
    @db.execute('CREATE TABLE IF NOT EXISTS points(
                   point_id   INTEGER PRIMARY KEY,
                   point_name TEXT
                     UNIQUE NOT NULL,
                   latitude   REAL
                     CHECK(latitude >= -90 AND latitude <= 90),
                   longitude  REAL
                     CHECK(longitude >= -180 AND longitude <= 180),
                   altitude   REAL
                     CHECK(altitude >= -10000 AND altitude <= 100000)
                 );')

    @db.execute('CREATE TABLE IF NOT EXISTS temperature(
                   point_id    INTEGER,
                   obs_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
                   temperature REAL NOT NULL
                               CHECK(temperature > -273.15),
                   PRIMARY KEY(point_id, obs_at),
                   FOREIGN KEY(point_id) REFERENCES points(point_id)
                 );')

    @db.execute('CREATE TABLE IF NOT EXISTS humidity(
                   point_id  INTEGER,
                   obs_at    DATETIME
                     DEFAULT CURRENT_TIMESTAMP,
                   humidity  REAL NOT NULL
                     CHECK(humidity >= 0 AND humidity <= 100),
                   PRIMARY KEY(point_id, obs_at),
                   FOREIGN KEY(point_id) REFERENCES points(point_id)
                 );')

    @db.execute('CREATE TABLE IF NOT EXISTS pressure(
                   point_id  INTEGER,
                   obs_at    DATETIME
                     DEFAULT CURRENT_TIMESTAMP,
                   pressure  REAL NOT NULL
                     CHECK(pressure >= 0 AND pressure <= 2000),
                   PRIMARY KEY(point_id, obs_at),
                   FOREIGN KEY(point_id) REFERENCES points(point_id)
                 );')
  end

  # 地点情報を追加
  def add_point(point_name, latitude, longitude, altitude)
    res = nil
    @db.transaction do
      @db.execute('INSERT OR IGNORE INTO points 
                     (point_name, latitude,
                      longitude, altitude)
                     VALUES (:point_name, :latitude,
                             :longitude, :altitude)',    
                  point_name: point_name,
                  latitude:   latitude,
                  longitude:  longitude,
                  altitude:   altitude)
      res = @db.execute('SELECT * FROM points
                           WHERE point_name = :point_name',
                        point_name: point_name)
      return {status: true, data: res}
    end
  rescue => e
    return { status:  false,
             code:    e.class.to_s,
             message: e.message }
  end

  # 観測データを追加
  def add_entry(point_id, type, value)
    unless type?(type)
      return { status:  false,
               code:    'Heyadas::InvalidType',
               message: 'Invalid data type.' }
    end
    res = nil
    @db.transaction do
      @db.execute("INSERT INTO #{type}(point_id, #{type})
                    VALUES(:point_id, :value)",
                  point_id: point_id, value: value)
      res = @db.execute("SELECT * FROM #{type}
                          WHERE obs_at = (
                            SELECT MAX(obs_at) FROM #{type}
                          );")
    end
    return {status: true, data: res}
  rescue => e
    return { status:  false,
             code:    e.class.to_s,
             message: e.message }
  end

  # 地点一覧を取得
  def get_points
    list = @db.execute('SELECT * FROM points;')
    return {status: true, data: list}
  end

  # 地点IDから地点情報を取得
  def get_point(point_id)
    point = @db.execute('SELECT * FROM points
                           WHERE point_id = :point_id',
                        point_id: point_id)
    return {status: true, data: point[0]}
  end

  # 地点名から地点情報を取得
  def get_point_by_name(point_name)
    point = @db.execute('SELECT * FROM points
                           WHERE point_name = :point_name',
                        point_name: point_name)
    return {status: true, data: point[0]}
  end

  # 過去n時間の観測データを取得
  def get_entry_nhours(point_id, type, nhour)
    unless type?(type)
      return { status:  false,
               code:    'Heyadas::InvalidType',
               message: 'Invalid data type.' }
    end
 
    between = "-#{nhour.to_f} hours"
    res = @db.execute("SELECT * FROM #{type}
                         WHERE point_id = :point_id
                           AND obs_at >= datetime(CURRENT_TIMESTAMP, :between);",
                      point_id: point_id, between: between)
    return {status: true, data: res}
  end

  def type?(type)
    return types.include?(type)
  end

  def types
    return ['temperature', 'humidity', 'pressure']
  end
end
