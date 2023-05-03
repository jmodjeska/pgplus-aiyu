# PG+ 爱语 (Aiyu) [WIP - Not Ready for Use]
爱语 (Aiyu) is a ChatGPT-powered, Ruby chatbot designed to interact, as a standalone user, with PG+ talkers. 

## Synopsis

[local]
```
    $ ruby pgplus-aiyu.rb
    
    -=> Connecting to: uberworld_test
    Talker login successful for aiyu (use `tail -f logs/output.log` to follow along live)
```

[talker]
```
     ___________
     | UberLogIn `.   aiyu has connected to UberWorld ... 
     |___________,'    0.0.0.0
    ] {UberLogIn} aiyu enters UberWorld 

    .ai Good afternoon!
     You exclaim to aiyu 'Good afternoon!'
    $ > aiyu asks of you 'Good afternoon! How may I assist you today?'
````

## You Will Need

1. A working [PG+ talker](https://github.com/talkers/pgplus)
2. A reasonably current vintage of Ruby (this project was developed and tested on **Ruby >=3.0**)
3. An OpenAI (ChatGPT) [API key](https://platform.openai.com/account/api-keys)

## Installation

Clone this repo

    git clone https://github.com/jmodjeska/pgplus-aiyu/

Install dependencies

    bundle install

## Configuration

**On the talker ...**

1. Setup the `aiyu` character (you can name it whatever you want) as a regular resident, with a password, title, description, etc. At this time I do not recommend granting it the `robot` priv, but I'll work on enabling that in a future update.

**In aiyu/config.yaml ...**

1. Configure the test / prod talker credentials, IPs, ports, etc. 
1. **Make sure the prompt in config matches aiyu's prompt on your talker.** You have to get this exactly right or nothing will work. See [notes on prompt configuration here](https://github.com/jmodjeska/pgplus-test#prompt).

## Usage

```
$ ruby aiyu.rb -h

Synopsis: ruby aiyu.rb
  -p, --profile=<s>    Specify a talker profile (default: test)
  -h, --help           Show this message
```

Optionally, in another terminal window, you can watch things unfold in realtime with:

```
tail -f logs/output.log
```

And of course, login to your talker to interact with aiyu.

## TODO

* Smartbot code update for PG+ to allow aiyu to run as a proper robot 
* Terms of service / disclaimer for users to interact with aiyu / ChatGPT
* I don't know, probably other stuff!?
