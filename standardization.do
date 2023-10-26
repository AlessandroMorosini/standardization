clear
use "/Users/alessandromorosini/Desktop/Marketing Analytics/L5 - Group project/data/standardization_clean.dta"


* Does standardization help or not feedback sentiment?
*-------------------------------------------------
* focal independent variable: standardization
* focal dependent variable: feedback_sentiment


// let's run a regression
reg feedback_sentiment standardization


egen mean_standardization = mean(standardization)
gen c_standardization = standardization - mean_standardization

egen mean_feedback_sentiment = mean(feedback_sentiment)
gen c_feedback_sentiment = feedback_sentiment - mean_feedback_sentiment

reg c_feedback_sentiment c_standardization

* higher standardization --> lower feedback sentiment score? really?



* use logs for alternative interpretation in %
* generate ln_feedback_sentiment = ln(feedback_sentiment)
* generate ln_standardization = ln(standardization)
* reg ln_feedback_sentiment ln_standardization


// -------------------- CONFOUNDS -------------------
** can find some more

corr feedback_sentiment standardization has_dedicated_support_company  // not used 

corr feedback_sentiment standardization message_uniqueness // not used 

corr feedback_sentiment standardization response_time_company_mean_s // used

corr feedback_sentiment standardization word_count_company_mean // used 

corr feedback_sentiment standardization sentiment_score_company_mean // used


* solution --> controlling for confounds (keeping other factors constant, when estimating the effect).
* how do we know what to control for? theory, experience, reasoning.

reg c_feedback_sentiment c_standardization ///
word_count_company_mean  response_time_company_mean_s sentiment_score_company_mean




// ------------------------- MODERATORS -------------------    ADD MARGIN PLOTS EVERYWHERE

* market capitalization (categorical)
* encode MarketCap, gen(MarketCap_id) using encoded_MarketCap
reg c_feedback_sentiment c.c_standardization##i.encoded_MarketCap, allbaselevels


* likes to the first post of the customer
* claim: the more likes, the more important -> need a non stanrdardized answer
egen mean_likes = mean(like_count_focal_user_first_s)
gen c_like_count_focal_user_first_s = like_count_focal_user_first_s - mean_likes

reg c_feedback_sentiment c.c_standardization##c.c_like_count_focal_user_first_s  // not relevant statistically :( -> do not include


* use anger in the first message
egen mean_anger_focal_user_first = mean(anger_focal_user_first)
gen c_anger_focal_user_first = anger_focal_user_first - mean_anger_focal_user_first

reg c_feedback_sentiment c.c_standardization##c.c_anger_focal_user_first


* message sentiment 
egen mean_message_sentiment = mean(message_sentiment)
gen c_message_sentiment = message_sentiment - mean_message_sentiment

reg c_feedback_sentiment c.c_standardization##c.c_message_sentiment


* message uniqueness 
egen mean_message_uniqueness = mean(message_uniqueness)
gen c_message_uniqueness = message_uniqueness - mean_message_uniqueness

reg c_feedback_sentiment c.c_standardization##c.c_message_uniqueness


* number of likes 
egen mean_likes = mean(like_count_focal_user_first_s)
gen c_like_count_focal_user_first_s = like_count_focal_user_first_s - mean_likes

reg c_feedback_sentiment c.c_standardization##c.c_like_count_focal_user_first_s


* focal_user_followers_count_s


* addressed with first name
reg c_feedback_sentiment c.c_standardization i.addressed_with_name // , allbaselevels
reg c_feedback_sentiment c.c_standardization##c.c_message_sentiment


// ------------------------- MEDIATION ----------------------- 

// C-Path: confouders same as base ols
reg c_feedback_sentiment c_standardization ///
	word_count_company_mean sentiment_score_company_mean

// A-Path: confounders: message_uniqueness, focal_user_followers_count_s, like_count_focal_user_first_s
reg response_time_company_mean_s  /// 
c_standardization message_uniqueness focal_user_followers_count_s like_count_focal_user_first_s
	
// B-Path: confouders same as base ols
reg c_feedback_sentiment c_standardization ///
	word_count_company_mean sentiment_score_company_mean


// B-Path


// ----------------- 2SLS ------------------

// 2SLS: want to use an instrument to assess causality 
reg standardization response_time_company_mean_s message_uniqueness
estat overid


// --------------------- PANEL DATA ANALYSIS ----------------------

* the dataset has a panel structure.
tab Industry

encode Industry, generate(industry_id)
xtset industry_id

xtsum c_feedback_sentiment c_standardization ///
word_count_company_mean response_time_company_mean_s sentiment_score_company_mean message_uniqueness

* possibly add moderators
xtreg c_feedback_sentiment c_standardization message_sentiment response_time_company_mean_s sentiment_score_company_mean message_uniqueness has_dedicated_support_company user_tweet_count word_count_focal_user_mean anger_focal_user_first anger_focal_user_mean anger_company_first anger_company_mean, fe

* hausman fe_model re_model, sigmaless


// 2SLS

* find some instruments
corr feedback_sentiment c_standardization response_time_company_mean_s  // very low correlation, I think this might cause problems
corr feedback_sentiment c_standardization message_uniqueness  // negative correlation, see slides for interpretation
corr feedback_sentiment c_standardization like_count_focal_user_first_s  // negative correlation: more likes on user post? shared belief -> need less standardized response
corr feedback_sentiment c_standardization anger_focal_user_first // very good instruments: the angrier the user in first post, the less standardied the response

reg c_standardization message_uniqueness like_count_focal_user_first_s anger_focal_user_first  // only response_time_company_mean_s has unsignificant

** regress the independent variable on the exogenous variables + the two instruments (response_time_company_mean_s, has_dedicated_support_company, message_uniqueness)
reg c_standardization message_uniqueness anger_company_first has_dedicated_support_company count_tweets_foreigners message_sentiment sentiment_score_company_mean user_tweet_count word_count_focal_user_mean   response_time_company_mean_s

predict predicted_c_standardization, xb

reg c_feedback_sentiment predicted_c_standardization message_sentiment sentiment_score_company_mean user_tweet_count word_count_focal_user_mean anger_company_first anger_company_mean response_time_company_mean_s like_count_focal_user_first_s anger_focal_user_first 
