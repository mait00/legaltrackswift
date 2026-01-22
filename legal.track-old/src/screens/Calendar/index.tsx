import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, TouchableOpacity, FlatList, Text, Platform } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import {Calendar, LocaleConfig} from 'react-native-calendars';
import DayView from './../../components/Calendar/DayView';
import AsyncStorage from '@react-native-async-storage/async-storage';

LocaleConfig.locales['ru'] = {
	monthNames: ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'],
	monthNamesShort: ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'],
	dayNames: ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'],
	dayNamesShort: ['ВC','ПН','ВТ','СР','ЧТ','ПТ','СБ'],
	today: 'Aujourd\'hui'
};
LocaleConfig.defaultLocale = 'ru';

const months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
const days = ['Воскресенье','Понедельник','Вторник','Среда','Четверг','Пятница','Суббота'];

const CalendarScreen = ({getCalendar}) => {

	const navigation = useNavigation();

	const [rows, setRows] = React.useState([]);
	const [marked, setMarked] = React.useState({});
	const [allData, setAllData] = React.useState({});
	const [selectedDay, setSelectedDay] = React.useState(Common.getEngDate(new Date()));

	useFocusEffect(
		React.useCallback(() => {
		  if (Platform.OS === 'android') {
			refreshCalend();
		  }
			
		}, [])
	);

	useEffect(() => {
		refreshCalend();
	}, []);

	const refreshCalend = () => {
		AsyncStorage.getItem('calendar')
		.then(data => {
			console.warn('AsyncStorage: ', data);
			if (data && data.length) {
				data = JSON.parse(data);
				if (data) {
					calcCalendar(data);
				} else {
					
				}
			} else {
				
			}
			getCalendar()
			.then(data => {
				calcCalendar(data);
			})
			.catch(err => {

			});
		})
		.catch(err => {
			getCalendar()
			.then(data => {
				calcCalendar(data);
			})
			.catch(err => {

			});
		});
		
		return () => {
			
		};
	}

	getDayText = () => {
		let date = new Date(selectedDay);
		let dd = date.getDate();
		dd = dd < 10 ? '0' + dd : dd;
		return dd + ' ' + months[date.getMonth()] + ', ' + days[date.getDay()];
	}

	useEffect(() => {
		
	}, []);

	const calcCalendar = data => {
		let days = {};
		let markedObj = {};

		for (let i = 0; i < data.length; i++) {
			let start = data[i].datetime_start;
			start = Common.getEngDate(new Date(start));

			if (days[start]) {
				days[start].push({
					start: data[i].datetime_start,
					end: data[i].datetime_end,
					case_id: data[i].case_id,
					head: data[i].head,
					second: data[i].second_line,
					third: data[i].third_line,
					is_sou: data[i].is_sou,
				});
			} else {
				days[start] = [];
				markedObj[start] = {marked: true, dotColor: colors.ORANGE_COLOR};
				days[start].push({
					start: data[i].datetime_start,
					end: data[i].datetime_end,
					case_id: data[i].case_id,
					head: data[i].head,
					second: data[i].second_line,
					third: data[i].third_line,
					is_sou: data[i].is_sou,
				});
			}
		}

		if (!markedObj[Common.getEngDate(new Date())]) {
			markedObj[Common.getEngDate(new Date())] = {};
		}

		markedObj[Common.getEngDate(new Date())].selected = true;

		Object.keys(days).sort().forEach(function(key) {
			var value = days[key];
			delete days[key];
			days[key] = value;
		});

		console.warn(days);
		setMarked(markedObj);
		setAllData(days);

		if (days[Common.getEngDate(new Date())]) {
			setRows(days[Common.getEngDate(new Date())]);
		} else {
			setRows([]);
		}
	}

	const renderRow = (item: object, index: number) => {
		return (<DayView
			data={item}
			action={() => {
				if (item.is_sou) {
					navigation.navigate('SouCase3', {data: {id: item.case_id}});
				} else {
					navigation.navigate('Case3', {data: {id: item.case_id}});
				}
			}}
		/>);
	}

	return (
        <View style={{
			width: Common.getLengthByIPhone7(0),
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
        }}>
			<Calendar
				style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(32),
					// marginTop: Common.getLengthByIPhone7(28),
					// marginBottom: Common.getLengthByIPhone7(19),
				}}
				markedDates={marked}
				selected={selectedDay}
				monthNames={['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь']}
				monthNamesShort={['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь']}
				dayNames={['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag']}
				dayNamesShort={['ВC','ПН','ВТ','СР','ЧТ','ПТ','СБ']}
				current={selectedDay}
				onDayPress={day => {
					console.warn(allData[day.dateString]);

					let dd = JSON.parse(JSON.stringify(marked));
					let keys = Object.keys(dd);
					for (let i = 0; i < keys.length; i++) {
						dd[keys[i]].selected = false;
					}

					if (!dd[day.dateString]) {
						dd[day.dateString] = {};
					}
					dd[day.dateString].selected = true;
					console.warn(dd);
					setSelectedDay(day.dateString);
					setMarked(dd);
					if (allData[day.dateString]) {
						setRows(allData[day.dateString]);
					} else {
						setRows([]);
					}
				}}
				onDayLongPress={(day) => {console.log('selected day', day)}}
				monthFormat={'MMM yyyy'}
				onMonthChange={(month) => {console.log('month changed', month)}}
				hideArrows={false}
				// renderArrow={(direction) => (<Arrow/>)}
				hideExtraDays={false}
				disableMonthChange={false}
				firstDay={1}
				hideDayNames={false}
				showWeekNumbers={false}
				onPressArrowLeft={subtractMonth => subtractMonth()}
				onPressArrowRight={addMonth => addMonth()}
				disableArrowLeft={false}
				disableArrowRight={false}
				disableAllTouchEventsForDisabledDays={false}
				// renderHeader={(date) => {/*Return JSX*/}}
				enableSwipeMonths={true}
				theme={{
					backgroundColor: '#ffffff',
					calendarBackground: '#ffffff',
					textSectionTitleColor: '#b6c1cd',
					textSectionTitleDisabledColor: '#d9e1e8',
					selectedDayBackgroundColor: colors.ORANGE_COLOR,
					selectedDayTextColor: '#ffffff',
					todayTextColor: colors.TEXT_COLOR,
					dayTextColor: colors.TEXT_COLOR,
					textDisabledColor: 'rgba(194, 194, 194, 0.6)',
					dotColor: '#00adf5',
					selectedDotColor: '#ffffff',
					arrowColor: colors.ORANGE_COLOR,
					disabledArrowColor: '#d9e1e8',
					monthTextColor: colors.TEXT_COLOR,
					indicatorColor: 'red',
					textDayFontFamily: 'SFProText-Regular',
					textMonthFontFamily: 'SFProText-Regular',
					textDayHeaderFontFamily: 'SFProText-Regular',
					textDayFontWeight: 'normal',
					textMonthFontWeight: 'bold',
					textDayHeaderFontWeight: 'bold',
					textDayFontSize: Common.getLengthByIPhone7(17),
					textMonthFontSize: Common.getLengthByIPhone7(17),
					textDayHeaderFontSize: Common.getLengthByIPhone7(11)
				}}
			/>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				height: 1,
				backgroundColor: '#322661',
				marginTop: Common.getLengthByIPhone7(10)
			}} />
			<Text style={{
				marginTop: Common.getLengthByIPhone7(25),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProText-Regular',
				fontWeight: 'bold',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(17),
				lineHeight: Common.getLengthByIPhone7(22),
			}}
			allowFontScaling={false}>
				{getDayText()}
			</Text>
			<FlatList
                style={{
                    flex: 1,
                    backgroundColor: 'transparent',
                    width: Common.getLengthByIPhone7(0),
                    marginTop: Common.getLengthByIPhone7(15),
                }}
                contentContainerStyle={{
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                }}
				ListEmptyComponent={() => {
					return (<View style={{
						width: Common.getLengthByIPhone7(0),
						flex: 1,
						alignItems: 'center',
						justifyContent: 'center',
					}}>
						<Text style={{
							marginTop: Common.getLengthByIPhone7(50),
							color: colors.TEXT_COLOR,
							fontFamily: 'SFProText-Regular',
							fontWeight: 'normal',
							textAlign: 'center',
							fontSize: Common.getLengthByIPhone7(17),
							lineHeight: Common.getLengthByIPhone7(22),
						}}
						allowFontScaling={false}>
							Событий нет
						</Text>
					</View>);
				}}
                bounces={true}
                removeClippedSubviews={false}
                scrollEventThrottle={16}
                data={rows}
                extraData={rows}
                keyExtractor={(item, index) => index.toString()}
                renderItem={({item, index}) => renderRow(item, index)}
            />
		</View>
	);
};

const mstp = (state: RootState) => ({
	// bills: state.bills.bills,
});

const mdtp = (dispatch: Dispatch) => ({
    getCalendar: () => dispatch.all.getCalendar(),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(CalendarScreen);
