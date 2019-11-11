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

    /** Default constructor */
    private Counter()
    {
        logger = LogManager.getLogger(this.getClass());
        loadProperties();
    }

    /** load the database information from the properties file */
    private void loadProperties()
    {
        try
        {
            this.dbProperties = new Properties();
            dbProperties.load(Counter.class.getResourceAsStream("/db_info.properties"));
        }
        catch (IOException ioe)
        {
            logger.error(String.format("Error: '%s' while loading the database info", ioe));
        }
    }

    /** create connection to the database */
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

    /** close open connection */
    private void closeConnection(Connection connection)
    {
        if(connection != null)
        {
            try
            {
                connection.close();
            }
            catch (SQLException e)
            {
                logger.error(String.format("Error: '%s' while closing the connection", e));
            }
        }
    }

    /**
     * periodically every 2 seconds connect to the database and try to write integer number
     * if database is unreachable, it will wait and retry again
     */
    private void save()
    {
        Connection connection = null;
        try
        {
            String sql = "INSERT INTO count VALUES (?)";
            int i = 0;
            while (i < Integer.MAX_VALUE)
            {
                connection = createConnection();
                if(connection.isValid(2))
                {
                    connection.setNetworkTimeout(Executors.newSingleThreadExecutor(), 2000);
                    PreparedStatement preparedStatement = connection.prepareStatement(sql);
                    preparedStatement.setInt(1, i);
                    preparedStatement.executeUpdate();
                    logger.info("Trying to insert {}", i);
                    i++;
                }
                else
                {
                    logger.info("Connection lost when trying to insert {}, retrying...", i);
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
        finally
        {
            closeConnection(connection);
        }
    }

    /** main */
    public static void main(String... args)
    {
        Counter counter = new Counter();
        counter.save();
    }
}
