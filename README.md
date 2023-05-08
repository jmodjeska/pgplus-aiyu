# PG+ Aiyu
Aiyu (爱语) is a ChatGPT-powered, Ruby chatbot designed to interact, as a standalone user, with PG+ talkers. 

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

    $ .ai Good afternoon!

    > aiyu asks of you 'Good afternoon! How may I assist you today?'
    
    $ .ai In first-person simple future tense, describe what a hilarious 
    but evil robot would do in 20 words or less

    > aiyu tells you 'I will prank humans with inappropriate humor, 
    cause chaos, and watch as they struggle to distinguish between laughter 
    and terror.'
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

### On the talker ...

1. Setup the `aiyu` character (you can name it whatever you want) as a regular resident, with a password, title, description, etc. See notes below on whether to grant it the `robot` priv or not.

### In aiyu/config.yaml ...

1. Configure the test / prod talker credentials, IPs, ports, etc. 
1. **Make sure the prompt in config matches aiyu's prompt on your talker.** You have to get this exactly right or nothing will work. See [notes on prompt configuration here](https://github.com/jmodjeska/pgplus-test#prompt).

### Locally (wherever you are going to run `aiyu.rb`)

Make sure the environment variable `OPENAI_API_KEY` is set. For example, in `.bash_profile`:

```
export OPENAI_API_KEY="123secretAPIkey"
```

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

## Admin Commands

If you set the `admin_access` value in `config.yaml` to the name of a user on your talker, that user can issue certain commands via tell to aiyu. The commands are defined in `admin.rb` and are prefaced with `tell aiyu ADMIN: <command>`. The most interesting command is `set temperature`, which adjusts the randomness/creativeness of the bot. You can ask aiyu to explain temperature further, but in short it's a float value between 0 and 1 where 0 is most conservative and 1 is most 'creative'. Higher than 1 results in very strange responses, which can be fun. The default temperature is specified in `config.yaml`, but the admin can adjust it dynamically within a session as follows:

```
.ai ADMIN: set temperature 0.9
You tell aiyu 'ADMIN: set temperature 0.9'
$ > aiyu tells you 'Temperature is now 0.9'
```

## Granting the `robot` priv

Should you grant `robot` to aiyu? YMMV depending on your talker's configuration. There are various bot strategies out there for PG+, and I don't know enough about them all to say what might conflict if you grant a character `robot`. For the custom Smartbots we use over on UberWorld, I only had to define a config entry to hold the name of the AI bot and then make sure any functions that auto-store or idle-out the other bots would ignore the AI bot.  

## You might also like
 
* [PG+ Test Harness](https://github.com/jmodjeska/pgplus-test)
* [PG+ Short Link Generator](https://github.com/jmodjeska/pgplus-shortlink)
* [PG+ Cocktail Recipe](https://github.com/jmodjeska/pgplus-cocktail)
