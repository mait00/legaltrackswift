import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, Text, View, Image, TouchableOpacity, Platform, Animated, Easing, Alert, ImageBackground } from 'react-native';
import { API, StorageHelper } from './../../services';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from './../../utilities/Common';

import { theme } from './../../../theme';
import { colors } from '../../styles';

const InstructionScreen = ({}) => {
  const isMount = useRef<boolean>(false);
  const navigation = useNavigation();
  const [body, setBody] = React.useState(null);
  const [page, setPage] = React.useState(0);

  useEffect(() => {
    setBody(render1());
	setPage(0);
  }, []);

  const render1 = () => {
	return (<View style={{
		width: Common.getLengthByIPhone7(0),
		flex: 1,
		alignItems: 'center',
		justifyContent: 'space-between',
	}}>
		<Text style={{
			marginTop: Common.getLengthByIPhone7(100),
			color: colors.ORANGE_COLOR,
			fontFamily: 'Montserrat-Bold',
			fontWeight: 'bold',
			textAlign: 'left',
			fontSize: Common.getLengthByIPhone7(36),
		}}
		allowFontScaling={false}>
			L<Text style={{
				color: 'white',
				fontFamily: 'Montserrat-Bold',
				fontWeight: 'bold',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(36),
			}}
			allowFontScaling={false}>
				egal.Track
			</Text>
		</Text>
		<View style={{
			width: Common.getLengthByIPhone7(0),
			borderTopLeftRadius: Common.getLengthByIPhone7(20),
			borderTopRightRadius: Common.getLengthByIPhone7(20),
			backgroundColor: 'white',
			paddingTop: Common.getLengthByIPhone7(30),
			paddingBottom: Common.getLengthByIPhone7(20),
			paddingLeft: Common.getLengthByIPhone7(30),
			paddingRight: Common.getLengthByIPhone7(30),
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(60),
				alignItems: 'flex-start',
			}}>
				<Text style={{
					color: colors.ORANGE_COLOR,
					fontFamily: 'Montserrat-Regular',
					fontWeight: '700',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(18),
				}}
				allowFontScaling={false}>
					Добро пожаловать
				</Text>
				<Text style={{
					marginTop: Common.getLengthByIPhone7(10),
					color: 'black',
					fontFamily: 'Montserrat-Regular',
					fontWeight: '500',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(18),
				}}
				allowFontScaling={false}>
					Пожалуйста, пройдите инструкцию по использованию приложения
				</Text>
			</View>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(60),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				marginTop: Common.getLengthByIPhone7(30),
			}}>
				<TouchableOpacity style={{

				}}
				onPress={() => {
					navigation.goBack(null);
				}}>
					<Text style={{
						color: colors.ORANGE_COLOR,
						fontFamily: 'Montserrat-Regular',
						fontWeight: '700',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(18),
					}}
					allowFontScaling={false}>
						Пропустить
					</Text>
				</TouchableOpacity>
				<TouchableOpacity style={{
					backgroundColor: colors.ORANGE_COLOR,
					width: Common.getLengthByIPhone7(130),
					height: Common.getLengthByIPhone7(52),
					borderRadius: Common.getLengthByIPhone7(6),
					alignItems: 'center',
					justifyContent: 'center'
				}}
				onPress={() => {
					setPage(1);
				}}>
					<Text style={{
						color: 'white',
						fontFamily: 'Montserrat-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(16),
					}}
					allowFontScaling={false}>
						Пройти
					</Text>
				</TouchableOpacity>
			</View>
		</View>
	</View>);
  }

	const renderPage = (icon, title, text) => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			flex: 1,
			alignItems: 'center',
			justifyContent: 'space-between',
		}}>
			<Image source={icon} style={{
				marginTop: Platform.OS === 'ios' ? Common.getLengthByIPhone7(90) : Common.getLengthByIPhone7(50),
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(10),
				height: Common.getLengthByIPhone7(280),
				resizeMode: 'contain',
			}}/>
			<View style={{
				width: Common.getLengthByIPhone7(0),
				borderTopLeftRadius: Common.getLengthByIPhone7(20),
				borderTopRightRadius: Common.getLengthByIPhone7(20),
				backgroundColor: 'white',
				paddingTop: Common.getLengthByIPhone7(30),
				paddingBottom: Common.getLengthByIPhone7(20),
				paddingLeft: Common.getLengthByIPhone7(30),
				paddingRight: Common.getLengthByIPhone7(30),
			}}>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(60),
					alignItems: 'flex-start',
				}}>
					<Text style={{
						color: colors.ORANGE_COLOR,
						fontFamily: 'Montserrat-Regular',
						fontWeight: '700',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(18),
					}}
					allowFontScaling={false}>
						{title}
					</Text>
					<Text style={{
						marginTop: Common.getLengthByIPhone7(10),
						color: 'black',
						fontFamily: 'Montserrat-Regular',
						fontWeight: '500',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(18),
					}}
					allowFontScaling={false}>
						{text}
					</Text>
				</View>
				<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(60),
					flexDirection: 'row',
					alignItems: 'center',
					justifyContent: 'space-between',
					marginTop: Common.getLengthByIPhone7(30),
				}}>
					<TouchableOpacity style={{

					}}
					onPress={() => {
						navigation.goBack(null);
					}}>
						<Text style={{
							color: colors.ORANGE_COLOR,
							fontFamily: 'Montserrat-Regular',
							fontWeight: '700',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(18),
						}}
						allowFontScaling={false}>
							Пропустить
						</Text>
					</TouchableOpacity>
					<TouchableOpacity style={{
						backgroundColor: colors.ORANGE_COLOR,
						width: Common.getLengthByIPhone7(130),
						height: Common.getLengthByIPhone7(52),
						borderRadius: Common.getLengthByIPhone7(6),
						alignItems: 'center',
						justifyContent: 'center'
					}}
					onPress={() => {
						if (page == 1) {
							setPage(2);
						} else if (page == 2) {
							setPage(3);
						} else if (page == 3) {
							setPage(4);
						} else if (page == 4) {
							setPage(5);
						} else if (page == 5) {
							setPage(6);
						} else if (page == 6) {
							setPage(7);
						} else if (page == 7) {
							setPage(8);
						} else if (page == 8) {
							setPage(9);
						} else if (page == 9) {
							setPage(10);
						} else if (page == 10) {
							setPage(11);
						}
					}}>
						<Text style={{
							color: 'white',
							fontFamily: 'Montserrat-Regular',
							fontWeight: '600',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(16),
						}}
						allowFontScaling={false}>
							Далее
						</Text>
					</TouchableOpacity>
				</View>
			</View>
		</View>);
	}

	useEffect(() => {
		if (page === 1) {
			setBody(renderPage(require('./../../assets/ic-image1.png'), 'Как добавить судебное дело?', 'В строке ввода укажите номер арбитражного дела или ссылку на дело СОЮ, на которое хотите подписаться. После этого добавленное дело будет синхронизироваться и далее будет добавлено в ваши подписки.'));
		} if (page == 2) {
			setBody(renderPage(require('./../../assets/ic-image2.png'), 'Как добавить арбитражное дело?', 'В этом разделе "АС" также можно подписаться на арбитражное дело в формате "А40-12345/21". На арбитражное дело можно еще подписаться, отсканировав QR код по кнопке, указанной выше.'));
		} else if (page == 3) {
			setBody(renderPage(require('./../../assets/ic-image3.png'), 'Как добавить дело судов общей юрисдикции?', `На этой странице можно подписаться на дело СОЮ. Для этого в строке ввода укажите ссылку на дело с сайта суда в формате:
			\nhttps://mos-gorsud.ru/mgs/services/cases/appeal-civil/details/b92d2a90-67d6-11ec-b336-4f28555a9cc5`));
		} else if (page == 4) {
			setBody(renderPage(require('./../../assets/ic-image4.png'), 'Как подписаться на компанию?', 'В строке ввода укажите название компании, на которую хотите подписаться, либо введите ее ИНН. Если существует несколько компаний с одинаковыми названиями, выберите из списка нужное вам. После подписки на компанию вы будете получать уведомления о поступающих к ней новых исках.'));
		} else if (page == 5) {
			setBody(renderPage(require('./../../assets/ic-image5.png'), 'Настройки дела', 'Справа от каждого дела есть меню, как показано выше. При нажатии на него вы сможете переименовать дело, поделиться ссылкой на него или удалить его из списка.'));
		} else if (page == 6) {
			setBody(renderPage(require('./../../assets/ic-image6.png'), 'Карточка дела', `В карточке дела вы можете:
			\n\u2010 переименовать дело;\n\u2010 включить/выключить уведомления;\n\u2010 перейти в дело на сайт суда;\n\u2010 поделиться ссылкой на дело;\n\u2010 добавить к делу заметку или аудиофайл.`));
		} else if (page == 7) {
			setBody(renderPage(require('./../../assets/ic-image7.png'), 'Уведомления', `При подписке на дело вы будете автоматически получать push-уведомления о каждом новом событии или изменении в деле, а также о ближайших судебных заседаниях за 3 и за 24 часа до их начала.
			\nУведомления можно отключить в карточке дела.`));
		} else if (page == 8) {
			setBody(renderPage(require('./../../assets/ic-image8.png'), 'Календарь судебных заседаний', `В календаре отображены судебные заседания по вашим делам. Дни заседаний отмечены оранжевой точкой.
			\nПри нажатии на конкретную дату внизу высвечиваются назначенные судебные заседания.`));
		} else if (page == 9) {
			setBody(renderPage(require('./../../assets/ic-image9.png'), 'Как узнать задержку по арбитражному делу?', `Задержки по вашим делам определяются автоматически и выводятся в данном разделе. Чтобы узнать задержку по делу, на которое вы не подписаны, введите номер дела в формате “А40-12345/22”.
			\nЗадержки по делам СОЮ не определяются.`));
		} else if (page == 10) {
			setBody(renderPage(require('./../../assets/ic-image10.png'), 'Практика', `Отслеживание судебной практики путем подписки на конкретное слово или фразу.
			\nС момента подписки вы будете получать уведомления о всех новых судебных актах, где упоминаются ваше слово или фраза.
			`));
		} else if (page == 11) {
			navigation.goBack(null);
		}
	}, [page]);

  return (
        <View style={{
            flex: 1,
            alignItems: 'center',
			backgroundColor: colors.MAIN_COLOR,
        }}>
			<ImageBackground source={require('./../../assets/ic-fon.png')}
				style={{
					width: Common.getLengthByIPhone7(0),
					flex: 1,
					resizeMode: 'cover',
					alignItems: 'center',
					justifyContent: 'space-between',
			}}
			>
				{body}
			</ImageBackground>
        </View>
  );
};

const mstp = (state: RootState) => ({
	// isRequestGoing: state.user.isRequestGoing,
});

const mdtp = (dispatch: Dispatch) => ({
// 	getProfile: () => dispatch.user.getProfile(),
//   getCalendar: () => dispatch.all.getCalendar(),
//   getNotifications: () => dispatch.all.getNotifications(),
});

export default connect(mstp, mdtp)(InstructionScreen);

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: theme.colors.backgroundColor,
  },
});
