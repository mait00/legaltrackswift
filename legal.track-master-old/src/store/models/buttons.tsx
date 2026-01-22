//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';
import AsyncStorage from '@react-native-async-storage/async-storage';

type ButtonState = {
	buttonIndex: number,
	showMenu: boolean,
};

const buttons = createModel<RootModel>()({
	state: {
		buttonIndex: -1,
		showMenu: false,
	} as ButtonState, 
	reducers: {
		setButtonIndex: (state, payload: number) => ({
			...state,
			buttonIndex: payload,
		}),
		setShowMenu: (state, payload: boolean) => ({
			...state,
			showMenu: payload,
		}),
	},
	effects: (dispatch) => {
		return {
			async getFavorites(): Promise<any> {
				const data = await AsyncStorage.getItem('favorites');
				if (data && data.length) {
					data = JSON.parse(data);
					if (data) {
						dispatch.buttons.setFavorites(data);
					} else {
						dispatch.buttons.setFavorites([]);
					}
				} else {
					dispatch.buttons.setFavorites([]);
				}
			},
			async like(id): Promise<any> {
				let array = [];
				const data = await AsyncStorage.getItem('favorites');
				if (data && data.length) {
					console.warn('like: ', typeof data);
					data = JSON.parse(data);
					if (data) {
						array = data;
					}
				}
				// console.warn('like: ', array);
				if (array.includes(id)) {
					for(let i = 0; i < array.length; i++) {
						if (array[i] === id) { 
							array.splice(i, 1);
							break;
						}
					}	
				} else {
					array.push(id);
				}
				console.warn('array: ', array);
				dispatch.buttons.setFavorites(array);
				if (array.length) {
					AsyncStorage.setItem('favorites', JSON.stringify(array));
				} else {
					AsyncStorage.setItem('favorites', '');
				}
			},
		}
	},
});

export default buttons;