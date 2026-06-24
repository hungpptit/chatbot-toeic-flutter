'use strict';
import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class UserSubscription extends Model {
    static associate(models) {
      UserSubscription.belongsTo(models.User, { foreignKey: 'userId', onDelete: 'CASCADE' });
      UserSubscription.belongsTo(models.Subscription, { foreignKey: 'subscriptionId', onDelete: 'SET NULL' });
    }
  }

  UserSubscription.init({
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    subscriptionId: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    startDate: {
      type: DataTypes.DATE,
      allowNull: false
    },
    endDate: {
      type: DataTypes.DATE,
      allowNull: false
    },
    status: {
      type: DataTypes.STRING(50),
      allowNull: false,
      defaultValue: 'active'
    }
  }, {
    sequelize,
    modelName: 'UserSubscription',
    tableName: 'UserSubscriptions',
    timestamps: true,
  });

  return UserSubscription;
};
