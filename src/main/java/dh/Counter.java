package dh;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.concurrent.Executors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.postgresql.util.PSQLException;

public class Counter
{
    Logger logger = LogManager.getLogger(this.getClass());

    private Connection createConnection() throws InterruptedException
    {
        Connection connection = null;
        while(connection == null)
        {
            try
            {
                Class.forName("org.postgresql.Driver");
                connection = DriverManager.getConnection("jdbc:postgresql://localhost:5440,localhost:5441/counter?targetServerType=master&autosave=always", "postgres", "postgres");
                Thread.sleep(1000);
            }
            catch (PSQLException e)
            {
                logger.error(String.format("Error: '%s'%nConnecting failed, retrying...", e.getServerErrorMessage()));
            }
            catch (SQLException | ClassNotFoundException e)
            {
                logger.error(String.format("Error: '%s'%nConnecting failed, retrying...", e));
            }
        }
        logger.info("Connection established!");
        return connection;
    }

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
                connection.setNetworkTimeout(Executors.newSingleThreadExecutor(), 2000);
                PreparedStatement preparedStatement = connection.prepareStatement(sql);
                preparedStatement.setInt(1, i);
                preparedStatement.executeUpdate();
                logger.info(String.format("trying to insert '%s'", i));
                i++;
                Thread.sleep(1500);
            }
        }
        catch (SQLException | InterruptedException e)
        {
            logger.error(e);
        }

    }

    public static void main(String... args)
    {
        Counter counter = new Counter();
        counter.save();
    }
}
