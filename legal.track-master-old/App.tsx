import React from 'react';
import Router from './src/navigation/Router';
import useAppState from 'react-native-appstate-hook';
import { Provider } from 'react-redux';
import { theme } from './theme';
import { ThemeProvider } from 'styled-components';
import store from './src/store';
import MenuModalView from './src/components/MenuModalView';

const App = () => {

  useAppState({
    onChange: (newAppState) => console.warn('App state changed to ', newAppState),
    onForeground: () => console.warn('App went to Foreground'),
    onBackground: () => console.warn('App went to background'),
  });

  return (
    <Provider store={store}>
        <ThemeProvider theme={theme}>
          <Router />
        </ThemeProvider>
    </Provider>
  );
};

export default App;