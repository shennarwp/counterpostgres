package dh;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Properties;
import java.util.concurrent.Executors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.postgresql.util.PSQLException;

public class Counter
{
    private Logger logger;
    private Properties dbProperties;

    /**
     * Default constructor
     */
    private Counter()
    {
        logger = LogManager.getLogger(this.getClass());
        loadProperties();
    }

    /**
     * load the database information from the properties file
     */
    private void loadProperties()
    {
        try {
            this.dbProperties = new Properties();
            dbProperties.load(Counter.class.getResourceAsStream("/db_info.properties"));
        }
        catch (IOException ioe)
        {
            logger.error(String.format("Error: '%s' while loading the database info", ioe));
        }
    }

    /**
     * create connection to the database
     * @return the connection
     */
    private Connection createConnection()
    {
        Connection connection = null;
        while(connection == null)
        {
            try
            {
                connection = DriverManager.getConnection(dbProperties.getProperty("url"), dbProperties);
            }
            catch (PSQLException e)
            {
                logger.error(String.format("Error: '%s' while obtaining a connection, retrying...", e.getServerErrorMessage()));
            }
            catch (SQLException e)
            {
                logger.error(String.format("Error: '%s' while obtaining a connection, retrying...", e));
            }
        }
        logger.info("Connection established!");
        return connection;
    }

    /**
     * periodically every 2 seconds connect to the database and try to write integer number
     * if database is unreachable, it will wait and retry again
     */
    private void save()
    {
        Connection connection;
        int i = 0;
        try
        {
            String sql = "INSERT INTO count VALUES (?)";
            while (true)
            {
                connection = createConnection();
                if(connection.isValid(2))
                {
                    connection.setNetworkTimeout(Executors.newSingleThreadExecutor(), 2000);
                    PreparedStatement preparedStatement = connection.prepareStatement(sql);
                    preparedStatement.setInt(1, i);
                    preparedStatement.executeUpdate();
                    logger.info(String.format("Trying to insert '%s'", i));
                    i++;
                }
                else
                {
                    logger.info(String.format("Connection lost when trying to insert '%s', retrying...", i));
                    continue;
                }
                Thread.sleep(2000);
            }
        }
        catch (InterruptedException ie)
        {
            Thread.currentThread().interrupt();
            logger.error(String.format("Error: '%s' . Program interrupted!", ie));
        }
        catch (SQLException se)
        {
            logger.error(String.format("Error: '%s' while trying to write to the database", se));
        }

    }

    /**
     * main
     */
    public static void main(String... args)
    {
        Counter counter = new Counter();
        counter.save();
    }
}
