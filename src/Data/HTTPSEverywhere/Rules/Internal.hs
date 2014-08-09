module Data.HTTPSEverywhere.Rules.Internal (
  getRulesetsMatching,
  havingRulesThatTrigger,
  havingCookieRulesThatTrigger,
  setSecureFlag
) where

import Prelude hiding (readFile, filter)
import Control.Applicative ((<*>), (<$>))
import Control.Lens ((&))
import Control.Monad ((<=<), join)
import Data.Bool (bool)
import Data.Functor.Infix ((<$$>))
import Data.List (find)
import Data.Maybe (isJust)
import qualified Data.HTTPSEverywhere.Rules.Raw as Raw (getRule, getRules)
import Data.Text (Text)
import Network.HTTP.Client (Cookie(..))
import Pipes (Producer, Consumer, for, each, await, yield, lift, (>->))
import Pipes.Prelude (filter)

import Data.HTTPSEverywhere.Rules.Internal.Parser (parseRuleSets)
import Data.HTTPSEverywhere.Rules.Internal.Types (RuleSet(..), Target(..), Exclusion(..), Rule(..), CookieRule(..))

getRulesets :: Producer RuleSet IO ()
getRulesets = lift Raw.getRules
          >>= flip (for . each) (flip (for . each) yield <=< lift . (parseRuleSets <$$> Raw.getRule))

getRulesetsMatching :: Text -> Producer RuleSet IO ()
getRulesetsMatching url = getRulesets
                      >-> filter (flip hasTargetMatching url)
                      >-> filter (not . flip hasExclusionMatching url)

havingRulesThatTrigger :: Text -> Consumer RuleSet IO (Maybe Text)
havingRulesThatTrigger url = flip hasTriggeringRuleOn url <$> await
                         >>= maybe (havingRulesThatTrigger url) (return . Just)

havingCookieRulesThatTrigger :: Cookie -> Consumer RuleSet IO Bool
havingCookieRulesThatTrigger cookie = flip hasTriggeringCookieRuleOn cookie <$> await
                                  >>= bool (havingCookieRulesThatTrigger cookie) (return True)

hasTargetMatching :: RuleSet -> Text -> Bool
hasTargetMatching ruleset url = getTargets ruleset <*> [url] & or
  where getTargets = getTarget <$$> ruleSetTargets

hasExclusionMatching :: RuleSet -> Text -> Bool
hasExclusionMatching ruleset url = getExclusions ruleset <*> [url] & or & not
  where getExclusions = getExclusion <$$> ruleSetExclusions

hasTriggeringRuleOn :: RuleSet -> Text -> Maybe Text -- Nothing ~ False
hasTriggeringRuleOn ruleset url = getRules ruleset <*> [url] & find isJust & join
  where getRules = getRule <$$> ruleSetRules

hasTriggeringCookieRuleOn :: RuleSet -> Cookie -> Bool
hasTriggeringCookieRuleOn ruleset cookie = getCookieRules ruleset <*> [cookie] & or
  where getCookieRules = getCookieRule <$$> ruleSetCookieRules

setSecureFlag :: Cookie -> Cookie
setSecureFlag cookie = cookie { cookie_secure_only = True }