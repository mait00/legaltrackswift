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
	showItemMenu: boolean,
	showScanner: boolean,
	showRecord: boolean,
	showNote: boolean,
	menuMode: boolean,
	noteId: number,
	noteText: string,
};

const buttons = createModel<RootModel>()({
	state: {
		buttonIndex: -1,
		showMenu: false,
		showItemMenu: false,
		menuMode: false,
		showScanner: false,
		showRecord: false,
		showNote: false,
		noteId: 0,
		noteText: '',
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
		setShowRecord: (state, payload: boolean) => ({
			...state,
			showRecord: payload,
		}),
		setNoteId: (state, payload: boolean) => ({
			...state,
			noteId: payload,
		}),
		setNoteText: (state, payload: boolean) => ({
			...state,
			noteText: payload,
		}),
		setShowNote: (state, payload: boolean) => ({
			...state,
			showNote: payload,
		}),
		setShowItemMenu: (state, payload: boolean) => ({
			...state,
			showItemMenu: payload,
		}),
		setShowScanner: (state, payload: boolean) => ({
			...state,
			showScanner: payload,
		}),
		setMenuMode: (state, payload: boolean) => ({
			...state,
			menuMode: payload,
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