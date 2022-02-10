import React from 'react';
import styles from './LandingHeader.module.css';
import closeButtonImage from "../../assets/images/landing-close-button.svg";
import { runningOnWebRenderer } from '../../helpers/utils';
import MaskedDiv from '../atoms/masked/MaskedDiv';
import PrimaryButton from "../primaryButton/PrimaryButton";

import closePtOsLandingWindow from '../../services/closePtOsLandingWindow';


export default () => {
  return (
    <header className={styles.header}>
      <div className={styles.logoContainer}>
        <h1>
          Welcome to <span className="green">pi-topOS</span>
        </h1>
      </div>
      {runningOnWebRenderer() &&
        <MaskedDiv
          className={styles.closeButtonDiv}
          mask={`url(${closeButtonImage})`}
        >
          <PrimaryButton
            className={styles.closeButton}
            onClick={() => closePtOsLandingWindow().catch(() => null)}
            aria-label="close-window"
          >
          </PrimaryButton>
        </MaskedDiv>
      }
    </header>
  );
};
