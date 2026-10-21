package com.asistencia.config;

import com.asistencia.shared.application.UnitOfWork;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

@Configuration
public class CoreConfig {

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }

    @Bean
    UnitOfWork unitOfWork(PlatformTransactionManager tx) {
        TransactionTemplate template = new TransactionTemplate(tx);
        return new UnitOfWork() {
            @Override
            public <T> T inTransaction(java.util.function.Supplier<T> work) {
                return template.execute(status -> work.get());
            }
        };
    }
}
