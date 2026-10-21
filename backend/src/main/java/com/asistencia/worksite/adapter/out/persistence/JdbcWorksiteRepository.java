package com.asistencia.worksite.adapter.out.persistence;

import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.worksite.application.port.WorksiteRepository;
import com.asistencia.worksite.domain.Worksite;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcWorksiteRepository implements WorksiteRepository {

    private static final String COLUMNS = "id, name, address, lat, lon, radius_m, active";

    private final JdbcClient jdbc;

    public JdbcWorksiteRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Worksite> findById(long id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM worksite WHERE id = ?").param(id).query(this::map).optional();
    }

    @Override
    public List<Worksite> findAll() {
        return jdbc.sql("SELECT " + COLUMNS + " FROM worksite ORDER BY name").query(this::map).list();
    }

    @Override
    public Worksite save(Worksite w) {
        if (w.id() == null) {
            long id = jdbc.sql("""
                            INSERT INTO worksite (name, address, lat, lon, radius_m, active)
                            VALUES (?, ?, ?, ?, ?, ?) RETURNING id""")
                    .params(w.name(), w.address(), w.center().lat(), w.center().lon(), w.radiusMeters(), w.active())
                    .query(Long.class).single();
            return w.withId(id);
        }
        jdbc.sql("UPDATE worksite SET name = ?, address = ?, lat = ?, lon = ?, radius_m = ?, active = ? WHERE id = ?")
                .params(w.name(), w.address(), w.center().lat(), w.center().lon(), w.radiusMeters(), w.active(), w.id())
                .update();
        return w;
    }

    private Worksite map(ResultSet rs, int row) throws SQLException {
        return new Worksite(rs.getLong("id"), rs.getString("name"), rs.getString("address"),
                new GeoPoint(rs.getDouble("lat"), rs.getDouble("lon")), rs.getInt("radius_m"), rs.getBoolean("active"));
    }
}
