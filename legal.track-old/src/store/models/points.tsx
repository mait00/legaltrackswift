//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';

type PointState = {
	isRequestGoing: false,
	pointsRaw: [],
	points: {
		points: [],
		pointsRaw: [],
		success: false,
		message: null,
		errors: null,
	},
};

const points = createModel<RootModel>()({
	state: {
		isRequestGoing: false,
		pointsRaw: [],
		points: {
			points: [],
			success: false,
			message: null,
			errors: null,
		},
	} as PointState, 
	reducers: {
		setRequestGoingStatus: (state, payload: boolean) => ({
			...state,
			isRequestGoing: payload,
		}),
		setPoints: (state, payload: object) => ({
			...state,
			points: { points: payload.points, success: payload.success, message: payload.message },
		}),
		setPointsRaw: (state, payload: object) => ({
			...state,
			pointsRaw: payload.points,
		}),
	},
	effects: (dispatch) => {
		return {
			async getPoints(): Promise<any> {
				dispatch.points.setRequestGoingStatus(true);
				const response = await API.common.getPoints()
				console.warn('getPoints -> response', response);
				dispatch.points.setRequestGoingStatus(false);
				dispatch.points.setPoints(response.data);
				dispatch.points.setPointsRaw(response.data);
			},
		}
	},
});

export default points;