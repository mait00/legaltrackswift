import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import { Image } from 'react-native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import { colors } from '../styles';
import SplashScreen from '../screens/Splash';
import PhoneScreen from '../screens/Phone';
import CodeScreen from '../screens/Code';
import ProfileScreen from '../screens/Profile';
import Main from './../screens/Main';
import CalendarScreen from '../screens/Calendar';
import DelayScreen from '../screens/Delay';
import NotificationsScreen from '../screens/Notifications';
import ChatScreen from '../screens/Chat';
import PracticeScreen from '../screens/Practice';
import TarifsScreen from '../screens/Tarifs';
import FaqScreen from '../screens/Faq';

import MainHeader from './../components/MainHeader';
import HeaderView from '../components/HeaderView';
import MenuModalView from '../components/MenuModalView';

// import AddBill from '../components/buttons/AddBill';
// import AddTransaction from '../components/buttons/AddTransaction';
// import Close from '../components/buttons/Close';

export const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

const MainTab = () => {
  return (
      <Stack.Navigator>
          <Stack.Screen name={'Main'} component={Main} options={{
            headerTransparent: false,
            header: (props) => <MainHeader {...props} letter={'L'} title={'egal.Track'} />,
            // headerRight: (props) => (
            //   <MapList
            //     {...props}
            //   />
            // ),
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
          <Stack.Screen
            name={'Profile'}
            component={ProfileScreen}
            options={{
                headerShown: true,
                gestureEnabled: true,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'П'}
                    word={'рофиль'}
                  />
                ),
                headerShadowVisible: false,
                headerBackTitleVisible: false,
                headerTintColor: '#EB5E1F',
                // headerBackImageSource: require(),
                // headerBackVisible: false,
            }}
          />
          <Stack.Screen
            name={'Faq'}
            component={FaqScreen}
            options={{
                headerShown: true,
                gestureEnabled: true,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'F'}
                    word={'.A.Q.'}
                  />
                ),
                headerShadowVisible: false,
                headerBackTitleVisible: false,
                headerTintColor: '#EB5E1F',
                // headerBackImageSource: require(),
                // headerBackVisible: false,
            }}
          />
          <Stack.Screen
            name={'Practice'}
            component={PracticeScreen}
            options={{
                headerShown: true,
                gestureEnabled: true,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'П'}
                    word={'рактика'}
                  />
                ),
                headerShadowVisible: false,
                headerBackTitleVisible: false,
                headerTintColor: '#EB5E1F',
                // headerBackImageSource: require(),
                // headerBackVisible: false,
            }}
          />
          <Stack.Screen
            name={'Chat'}
            component={ChatScreen}
            options={{
                headerShown: true,
                gestureEnabled: true,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'Т'}
                    word={'ехническая поддержка'}
                  />
                ),
                headerShadowVisible: false,
                headerBackTitleVisible: false,
                headerTintColor: '#EB5E1F',
                // headerBackImageSource: require(),
                // headerBackVisible: false,
            }}
          />
          <Stack.Screen
            name={'Tarifs'}
            component={TarifsScreen}
            options={{
                headerShown: true,
                gestureEnabled: true,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'Т'}
                    word={'арифы'}
                  />
                ),
                headerShadowVisible: false,
                headerBackTitleVisible: false,
                headerTintColor: '#EB5E1F',
                // headerBackImageSource: require(),
                // headerBackVisible: false,
            }}
          />
      </Stack.Navigator>
  );
}

const NotifyTab = () => {
  return (
      <Stack.Navigator>
          <Stack.Screen name={'Notifications'} component={NotificationsScreen} options={{
            headerTransparent: false,
            header: (props) => <MainHeader {...props} type={'small'} letter={'У'} title={'ведомления'} />,
            // headerRight: (props) => (
            //   <MapList
            //     {...props}
            //   />
            // ),
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
      </Stack.Navigator>
  );
}

const CalendarTab = () => {
  return (
      <Stack.Navigator>
          <Stack.Screen name={'Calendar'} component={CalendarScreen} options={{
            headerTransparent: false,
            header: (props) => <MainHeader {...props} type={'small'} letter={'К'} title={'алендарь'} />,
            // headerRight: (props) => (
            //   <MapList
            //     {...props}
            //   />
            // ),
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
      </Stack.Navigator>
  );
}

const DelayTab = () => {
  return (
      <Stack.Navigator>
          <Stack.Screen name={'Delay'} component={DelayScreen} options={{
            headerTransparent: false,
            header: (props) => <MainHeader {...props} type={'small'} letter={'З'} title={'адержки'} />,
            // headerRight: (props) => (
            //   <MapList
            //     {...props}
            //   />
            // ),
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
      </Stack.Navigator>
  );
}

const Tabs = () => {
  return (
      <Tab.Navigator screenOptions={({ route }) => ({
          tabBarStyle: {
            backgroundColor: colors.TABBAR_COLOR,
            borderTopWidth: 0,
            shadowColor: '#CED6E8',
            shadowOffset: { width: 0, height: 2 },
            shadowOpacity: 1,
            shadowRadius: 10,
            elevation: 4,
          },
          tabBarIcon: ({ focused, color, size }) => {
            let iconName;

            if (route.name === 'Objects') {
              iconName = require('./../assets/ic-tab-1.png');
            } else if (route.name === 'NotifyTab') {
              iconName = require('./../assets/ic-tab-2.png');
            } else if (route.name === 'CalendarTab') {
              iconName = require('./../assets/ic-tab-3.png');
            } else if (route.name === 'DelayTab') {
              iconName = require('./../assets/ic-tab-4.png');
            }

            // You can return any component that you like here!
            return (<Image
              source={iconName}
              style={{
                marginBottom: -10,
                resizeMode: 'contain',
                width: 24,
                height: 24,
                tintColor: color,
              }}
            />);
          },
          tabBarActiveTintColor: colors.ORANGE_COLOR,
          tabBarInactiveTintColor: colors.TABBAR_INACTIVECOLOR,
          tabBarLabelStyle: {
            marginBottom: -5,
            fontSize: 10,
            lineHeight: 12,
            fontWeight: '500',
            fontFamily: 'SFProText-Regular',
          }
          
        })}>
          <Tab.Screen name={'Objects'} component={MainTab} options={{
              title: 'Главная',
              headerShown: false,
          }}/>
          <Tab.Screen name={'NotifyTab'} component={NotifyTab} options={{
              title: 'Уведомления',
              headerShown: false,
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
          <Tab.Screen name={'CalendarTab'} component={CalendarTab} options={{
              title: 'Календарь',
              headerShown: false,
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
          <Tab.Screen name={'DelayTab'} component={DelayTab} options={{
              title: 'Задержки',
              headerShown: false,
              // animation: 'slide_from_bottom',
              // presentation: 'card',
          }}/>
      </Tab.Navigator>
  );
}

const EnterStack = () => {
  return (
      <Stack.Navigator>
          <Stack.Screen
            name={'Splash2'}
            component={SplashScreen}
            options={{
                headerShown: false,
            }}
          />
          <Stack.Screen
            name={'Phone'}
            component={PhoneScreen}
            options={{
                headerShown: false,
                animation: 'slide_from_bottom',
                presentation: 'card',
                gestureEnabled: false,
            }}
          />
          <Stack.Screen
            name={'Code'}
            component={CodeScreen}
            options={{
                headerShown: false,
            }}
          />
          <Stack.Screen
            name={'Profile2'}
            component={ProfileScreen}
            options={{
                headerShown: true,
                gestureEnabled: false,
                headerTitle: (props) => (
                  <HeaderView
                    {...props}
                    letter={'П'}
                    word={'рофиль'}
                  />
                ),
                headerLeft: (props) => {
                  return null;
                },
                headerShadowVisible: false,
                headerBackVisible: false,
            }}
          />
      </Stack.Navigator>
  );
}

export default function Router() {

  return (
    <NavigationContainer>
      <SafeAreaProvider>
        <Stack.Navigator>
          <Stack.Screen
            name={'Splash'}
            component={EnterStack}
            options={{
                headerShown: false,
            }}
          />
          <Stack.Screen name={'LoginIn'} component={Tabs} options={{
            animation: 'slide_from_bottom',
            presentation: 'card',
            headerShown: false,
            gestureEnabled: false,
          }}/>
        </Stack.Navigator>
        <MenuModalView />
      </SafeAreaProvider>
    </NavigationContainer>
  );
}
