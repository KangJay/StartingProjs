import java.net.*;
import java.io.*;
import java.util.Scanner;
import com.google.gson.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class WeatherGetter {

    private URL url;
    private URLConnection website;
    private HttpURLConnection http;
    private int resp_code;
    private String json_input;
    private Scanner input;
    private JsonObject json;	//Holds all json arrays, elements, etc. 
    private JsonObject weather; //Handles things pertaining to the weather itself 
    private JsonObject main;	//Handles data relating to primary stats (temperature, etc.)
    private JsonObject wind;	//Handles data relating to wind
    private JsonObject sys; 

    /**
	Precondition: None
	Postcondition: Returns a boolean 
	Sets the net object and looks for connection issues as well. 
    */
    private boolean setNetObjects(String url, int num_tries) throws MalformedURLException, IOException, InterruptedException, UnknownHostException{
    	if (num_tries == 3){
    		System.out.println("City may not exist or the service may be down. We apologize for the inconvenience. Please try again later.");
    		System.exit(1);
    	}
    	try {
            this.url = new URL(url);
            this.website = this.url.openConnection();
            this.http = (HttpURLConnection) website;	
            this.http.setInstanceFollowRedirects(true);	//Handle 300s in the case it ever arises. 
            this.resp_code = http.getResponseCode();	//Used to determine if it was successful            
            if (this.resp_code >= 400){ //Means the entered strings were invalid or cities don't exist. 
                //System.err.println("City name may not be in database or not exist!");
                Thread.sleep(num_tries * 2000);
                setNetObjects(url, num_tries + 1);
            }
        } catch(MalformedURLException me){	//Doesn't follow 'HTTP' formatting
            System.err.println("Malformed URL. Message: " + me.getCause());
            //me.printStackTrace();
        } catch(java.net.UnknownHostException e){
          Thread.sleep(num_tries * 2000);
          setNetObjects(url, num_tries + 1);
        } catch(IOException ioe){	
            System.err.println("IO Exception. Message: " + ioe.getCause());
            ioe.printStackTrace();
        } 
        return true; 
    }
    
    /**
	Precondition: 'url' is not null
	Postcondition: Either throws an exception or successfully sets objects 
	Constructor will create all necessary JSON containers and any net HTTP objects
	accordingly. 
    */
    public WeatherGetter(String url) throws MalformedURLException, IOException, InterruptedException, Exception{
        try {
        	setNetObjects(url, 0);
        } catch(MalformedURLException me){	//Doesn't follow 'HTTP' formatting
            System.err.println("Malformed URL. Message: " + me.getCause());
            //me.printStackTrace();
        } catch(java.net.UnknownHostException e1){
        	try {
        		System.err.println("Service unreached. Pinging again soon...");
        		Thread.sleep(2000);
        		setNetObjects(url, 0);
        	} catch(InterruptedException iee1){
        		System.err.println("Interrupted Exception with sleep method: " + iee1.getCause());
        	} catch(java.net.UnknownHostException e2){
        		try {
        			System.err.println("Service unreached. Pinging again soon...");
        			Thread.sleep(4000);
        			setNetObjects(url, 0);
        		} catch (InterruptedException iee2){
        			System.err.println("Interrupted Exception with sleep method: " + iee2.getCause());
        		} catch (java.net.UnknownHostException e3){
        			System.err.println("Service may be down. Please try again later!");
        			System.exit(1);
        		}
        	}
        }
    	set_json_objects();
    }

    /**
	Precondition: HTTP request was successful and connected to the site. 
	Postcondition: All JsonObjects are set and are not NULL. 
	Private helper setter method that'll just set all the JSON containers.
    */
    private void set_json_objects() throws IOException{
    	this.input = new Scanner(new InputStreamReader(website.getInputStream()));
       	this.json = new JsonParser().parse(json_input = getInput()).getAsJsonObject();
       	this.weather = json.get("weather").getAsJsonArray().get(0).getAsJsonObject();
       	this.main = json.get("main").getAsJsonObject();
       	this.wind = json.get("wind").getAsJsonObject();
       	this.sys = json.get("sys").getAsJsonObject();
       	this.input.close();
    }

    /**
	Helper method to aid in debugging. 
	Holds the string representation of the JSON. Used for debugging purposes only. 
    */
    private String getInput(){
        String json = "";
        while(input.hasNext()){
            json += input.next();
        }
        return json;
    }

    /**
    Precondition: None
    Postcondition: None
	Public interface for printing out the weather statistics. 
    */
    public void printStats(){
        privGetStats();
    }

    /**
	Helper method to convert Kelvin to Fahrenheit using the known formula. 
	Kelvin_Temp * (9/5) - 459.67
    */
    private double Kelv_to_Fahren(double kelvin){
    	return ((kelvin * 9) / 5) - 459.67;
    }

    /**
	Helper method to print the temperatures since they follow the same format. 
    */
    private void print_temps(){
    	System.out.printf("%nCurrent Temperature: %.2f degrees Fahrenheit%n", Kelv_to_Fahren(main.get("temp").getAsFloat()));
    	System.out.printf("Max Temperature: %.2f degrees Fahrenheit%n", Kelv_to_Fahren(main.get("temp_max").getAsFloat()));
    	System.out.printf("Min Temperature: %.2f degrees Fahrenheit%n%n", Kelv_to_Fahren(main.get("temp_min").getAsFloat()));
    }

    //https://stackoverflow.com/questions/17432735/convert-unix-time-stamp-to-date-in-java
    private void print_times(){
    	SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    	sdf.setTimeZone(java.util.TimeZone.getTimeZone("PST"));
    	System.out.println("Sunrise: " + sdf.format(new Date(sys.get("sunrise").getAsInt() * 1000L)) + " PST (YYYY-MM-DD HH:mm:ss)");
    	System.out.println("Sunset: " + sdf.format(new Date(sys.get("sunset").getAsInt() * 1000L)) + " PST (YYYY-MM-DD HH:mm:ss)");
    }

    private void privGetStats(){
        //System.out.println(json_input);
        //JsonObject json = new JsonParser().parse(json_input).getAsJsonObject();
        if (json.get("cod").getAsInt() >= 400){
        	System.err.println("City name not found or is invalid");
        	System.exit(1);
        }
        System.out.println("=================================================================");
        System.out.println("City Name: " + json.get("name").getAsString());
        System.out.println("Sky Description: " + weather.get("main").getAsString() + " and " + weather.get("description").getAsString());
        print_temps();
        System.out.println("Atsmospheric Pressure: " + main.get("pressure").getAsInt() + " hPa");
        System.out.println("Humidity: " + main.get("humidity").getAsInt() + "%");
        System.out.printf("Wind Speed: %.2f mph%n", wind.get("speed").getAsFloat() * 2.237); //(Meters per second) * 2.237 = miles per hour according to Google. 
        print_times();
        System.out.println("=================================================================");
    }

    //api.openweathermap.org/data/2.5/weather?q=London,uk  &APPID=3de97907c1f0637a55a8c253b198b1a2
    public static void main(String[] args) throws MalformedURLException, IOException, InterruptedException, Exception{
        String rest_request = "";
        String userIn = "";
        WeatherGetter wg;
       	if (args.length == 0){ //Multiple runs
       		String[] parse; 
       		Scanner userInput = new Scanner(System.in);
       		while (true){
       			System.out.println("Enter 'quit' to exit");
       			System.out.print("Enter a city name: ");
       			parse = userInput.nextLine().split(",");
       			if (parse.length > 1){
       				parse[parse.length - 1] = "," + parse[parse.length - 1];
       			}
       			if (parse[0].equalsIgnoreCase("quit")) break;
       			for (int i = 0; i < parse.length; i++){
       				userIn +=  " " + parse[i];
       			}
       			userIn = userIn.trim();
       			rest_request = "https://api.openweathermap.org/data/2.5/weather?q=" + userIn + "&APPID=3de97907c1f0637a55a8c253b198b1a2";
       			wg = new WeatherGetter(rest_request);
       			wg.printStats();
       			userIn = "";
       		}
       	} else {
       		for (int i = 0; i < args.length; i++){
       			userIn +=  " " + args[i];
       		}
       		userIn = userIn.trim();
       		rest_request = rest_request = "https://api.openweathermap.org/data/2.5/weather?q=" + userIn + "&APPID=3de97907c1f0637a55a8c253b198b1a2";
       		wg = new WeatherGetter(rest_request);
       		wg.printStats();
       	}
       	System.out.println("Thank you for using Ji's Weather app!");
    }
}
