import React from 'react';
import Router from './src/navigation/Router';
import {StatusBar, Platform} from 'react-native';
import useAppState from 'react-native-appstate-hook';
import { Provider } from 'react-redux';
import { theme } from './theme';
import { ThemeProvider } from 'styled-components';
import store from './src/store';
import LoadingView from './src/components/LoadingView';

const App = () => {

  useAppState({
    onChange: (newAppState) => console.warn('App state changed to ', newAppState),
    onForeground: () => {
      if (Platform.OS === 'ios') {
        StatusBar.setBarStyle('dark-content', true);
      }
    },
    onBackground: () => console.warn('App went to background'),
  });

  return (
    <Provider store={store}>
        <ThemeProvider theme={theme}>
          <Router />
          <LoadingView/>
        </ThemeProvider>
    </Provider>
  );
};

export default App;