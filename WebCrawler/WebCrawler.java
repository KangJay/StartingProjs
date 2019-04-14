import java.net.*;
import java.io.*;
import java.util.Scanner;
import java.util.ArrayList;
import java.util.regex.*;

//<a href=".*?">
// https://docs.oracle.com/javase/tutorial/networking/urls/readingURL.html

/**
 *  Author: Ji Kang
 *  CSS 490 Cloud Computing
 *  Professor Robert Dimpsey
 *  Program Assignment 1: Web Crawler
 *  Meant to get a starting http url and a number of hops. It will then connect to from the starting URL
 *  and hop the number of times taken in from command line. So if it was http://uw.edu 5 and there were
 *  no 400+ response codes, it will jump 5 times FROM the starting url meaning the Web Crawler has visited 6 total.
 *  If the Web Crawler lands on a 400+ site, it will terminate and print whatever it had leading up to that point.
 */
public class WebCrawler {

    private static ArrayList<String> visitedURL;
    private String entire_html;
    private String temp_html;
    private String website_url;
    private int max_hops;
    private URL url;
    private URLConnection website;
    private HttpURLConnection http;
    private int num_hops;
    private Scanner input;
    int response_code;
    Pattern pattern;

    /**
     *
     * @param url   : Starting url of our web crawler
     * @param max_hops  : Maximum number of hops it will take
     * @throws Exception    : Any connection exceptions that may be thrown as a result of invalid connections.
     * Precondition: URL and Max_hops have validity to a certain degree. max_hops will be a valid int,
     */
    public WebCrawler(String url, int max_hops) throws Exception {
        try{
            this.visitedURL = new ArrayList<String>();
            this.entire_html = "";
            this.temp_html = entire_html;
            this.website_url = url;
            this.max_hops = max_hops;
            this.url = new URL(website_url);
            this.website = this.url.openConnection();
            this.http = (HttpURLConnection) website;
            this.http.setInstanceFollowRedirects(true);
            this.num_hops = 0;
            this.input = new Scanner(new InputStreamReader(website.getInputStream()));
            this.response_code = http.getResponseCode();
            this.pattern = Pattern.compile("<a href=\"(http.*?)\"/?>?");
        } catch (Exception e){
            System.err.println("Invalid/Malformed URL");
            System.err.println("The cause: " + e.getMessage());
            print_results();
        }

    }

    /**
     * Public interface to execute web hopping
     * @throws Exception
     */
    public void hop_URL() throws Exception{
        private_hop_URL();
    }

    /**
     * Precondition: None
     * Postcondition: None
     * Populates the html String variable with the most recent hopped-to website.
     */
    private void get_html(){
        while(input.hasNextLine()){
            entire_html += input.nextLine() + "\n";
        }
        temp_html = entire_html.toLowerCase();
    }

    /**
     * Precondition: None
     * Postcondition: Validates and sets all variables
     * @param url is the url of the next potentially-hopped-to website
     * @throws Exception Would throw if java.net has any exceptions
     */
    private void validate_url(String url) throws Exception{

        try{
            URL tempURL = new URL(url);
            URLConnection temp_web = tempURL.openConnection();

            HttpURLConnection temp_http = (HttpURLConnection) temp_web;
            int temp_code = temp_http.getResponseCode();
            if (temp_code < 400){ //Handle only valid urls and populate instance variables to reflect current state.
                entire_html = "";
                temp_html = "";
                website_url = url;
                this.url = tempURL;
                this.website = temp_web;
                this.http = temp_http;
                this.http.setInstanceFollowRedirects(true);
                this.input = new Scanner(new InputStreamReader(website.getInputStream()));
                this.response_code = temp_code;
            }
        } catch (Exception e){
            System.err.println(e.getMessage());
        }

    }

    /**
     * Precondition: None
     * Postcondition: None
     * @throws Exception any Java.net exception that may pertain to connectivity to our website.
     * Private method that'll keep track of how many hops, which websites we hopped to, the current HTML for a href=http://... .com
     * URLS. It'll have special cases such as the first hop, redirection of 300s response codes, A non-valid URL, normal hits (200s)
     * and so on.
     * This web hopping mechanism will run until one of the following cases:
     * 1. It has hopped max_hops number of times by using num_hops as the variable keeping track
     * 2. The current web page's html does not have any a href HTTP urls OR any that we have not already seen.
     * 3. 400s response code is returned. In this case, the web crawler "hopped" to its demise.
     *
     * It utilizes temp_html as a placeholder to preserve the original html of the web page incase the WC stops there and presents
     * the current information.
     * Utilizes other private methods written in this class to help aid in the formation of the web crawler and its hopping.
     * Utilizes a regex pattern that may be found in the constructor of the class as well as the pattern matcher 'group' method
     * to utilize the (<parens>) to get the absolute URL and none of the other matched items.
     * It will do the following process until one of the above mentioned 3 cases occurr.
     * The Web crawler will start at a url given via construction at run-time. From there, it will download the html and save it to
     * a variable (entire_html). It utilizes the temp_html variable to scan via regex. When it finds a matched URL, it will then test
     * to see if we have already visited the URL OR if the URL is valid via our validate_url() method. If the URL is valid, it'll set
     * the instance variables to represent the current state of our Web Crawler. If it hopped to a 400, it has died.
     * If a URL is already seen, the method will parse the temp_html to get the html AFTER where the already seen link appeared
     * and search once more. It will increment num_hops by one whenever we visit a valid URL.
     * HTTPUrlconnection class' setInstanceFollowRedirects() is always set as true so 300s are taken care of for us using that method.
     *
     */
    private void private_hop_URL() throws Exception{
        Matcher match;
        while(true) {
            //System.out.println(website_url);
            if (entire_html.equals("")) get_html(); //First case
            if (num_hops == max_hops || max_hops == 0) break;
            if (!visitedURL.contains(website_url)) visitedURL.add(website_url);
            String new_url = "";
            if (response_code >= 300){
            	get_html();
                num_hops--;
            } else if (response_code > 400){
                System.out.println("Invalid URL visited. WebCrawler has \"hopped\" to its death. RIP WebCrawler 2019-2019.");
                print_results();
                break;
            }
            match = pattern.matcher(temp_html);
            if (match.find()) {
                new_url = match.group(1);
                if (visitedURL.contains(new_url + "/") || visitedURL.contains(new_url) || visitedURL.contains(new_url.substring(0, new_url.length() - 1))) {
                    temp_html = temp_html.substring(temp_html.indexOf(match.group(0)) + match.group(0).length() + 1);
                }
                if (!visitedURL.contains(new_url + "/") && !visitedURL.contains(new_url) && !visitedURL.contains(new_url.substring(0, new_url.length() - 1))){
                    validate_url(new_url);
                    num_hops++;
                    continue;
                }
                if (num_hops == max_hops) break;
                else {
                    temp_html = temp_html.substring(temp_html.indexOf(match.group(0)) + match.group(0).length() + 1);
                    continue;
                }
            } else { //Means no a href URLS are left in the entire html. Print the previous.
                System.out.println("No 'a href=\"http(s)://....\"' links in the HTML");
                break;
            }
        }
        print_results();
    }

    /**
     * Precondition: None
     * Postcondition: Output put out to standard output (Console for this assignment)
     * Will print out the statistics of our Web Crawler's journey
     */
    private void print_results(){
        System.out.println("Sites visited in order: (Includes any redirects also)");
        for (int i = 0; i < visitedURL.size(); i++){
            System.out.println("\t" + visitedURL.get(i));
        }
        System.out.println("URL of final site: " + website_url);
        System.out.println("Number of hops taken: " + num_hops);
        System.out.println("Max Number of hops: " + max_hops);
        System.out.println("HTML of final site hit:");
        System.out.println(entire_html);
    }

    public static void main(String[] args) throws Exception {
        //Everything below up to the next comment section is input validation
        String url = "";
        int hopNumber = 0;
        if (args.length != 2){
            System.err.println("Invalid number of arguments. Expected 2, got " + args.length + ". Exiting...");
            //System.exit(1);
        }
        try {
            url = args[0];
            if (!url.contains("http")){
                System.err.println("Not a HTTP URL");
                throw new Exception("Not a HTTP URL");
            } else {
                if (!url.contains("https")) url = url.replace("http", "https");
            }
            hopNumber = Integer.parseInt(args[1]);
            if (hopNumber < 0) throw new Exception("Negative number of hops!");
        } catch (Exception e){
            System.err.println("Either URL or number of hops is invalid!");
            System.err.println(e.getMessage());
            System.exit(1);
        }

        //Actual object creation and action execution
        try {
            WebCrawler wc = new WebCrawler(url, hopNumber);
            wc.hop_URL();
        } catch (Exception e) {
            System.err.println(e.getMessage());
        }
    }
}
