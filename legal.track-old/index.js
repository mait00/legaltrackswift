/**
 * @format
 */

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

// import * as Sentry from "@sentry/react-native";

// if (!__DEV__) {
// 	Sentry.init({*xwc4LLi
// 	  dsn:
// 		'https://4a0c891dd2aa4b16ad8ae77f28a63af2@o1092711.ingest.sentry.io/6111335',
// 	});
//   }
  
//   function root() {
// 	return __DEV__ ? Sentry.wrap(App) : App;
//   }

// *xwc4LLi

// 45.147.176.25

// AppRegistry.registerComponent(appName, root);
AppRegistry.registerComponent(appName, () => App);
