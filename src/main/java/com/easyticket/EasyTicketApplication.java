package com.easyticket;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

/**
 * Easy Ticket System
 * 
 */
@SpringBootApplication
@MapperScan("com.easyticket.mapper")
@EnableScheduling
@EnableTransactionManagement
public class EasyTicketApplication extends SpringBootServletInitializer{

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(EasyTicketApplication.class);
    }

    public static void main(String[] args) {
        System.out.println("=== Easy Ticket System Starting ===");
        SpringApplication.run(EasyTicketApplication.class, args);
        System.out.println("=== Easy Ticket System Started Successfully ===");
    }
} 
